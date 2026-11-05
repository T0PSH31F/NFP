#!/usr/bin/env python3
"""Idempotently provision OmniRoute provider connections and the Failover combo.

Runs from the omniroute systemd unit after `omniroute-ctl up`. Every operation is
"create if missing", so repeated boots converge without duplicating rows.

Secrets are never taken from argv:
  --admin-password-file  SOPS-rendered file containing the dashboard password
  --env-file             rendered OmniRoute env (provider API keys)

Exit code is always 0 unless login itself fails; a provisioning failure must not
wedge the unit (the container is already running by then).
"""

import argparse
import http.cookiejar
import json
import sys
import time
import urllib.error
import urllib.request

# provider id -> env var holding its API key
DIRECT_PROVIDERS = {
    "groq": "GROQ_API_KEY",
    "cerebras": "CEREBRAS_API_KEY",
    "nvidia": "NVIDIA_API_KEY",
    "nous-research": "NOUS_API_KEY",
    "openrouter": "OPENROUTER_API_KEY",
    "anthropic": "ANTHROPIC_API_KEY",
    "gemini": "GEMINI_API_KEY",
}

NODE_NAME = "ExtremeRouter"
NODE_PREFIX = "xr"
COMBO_NAME = "Failover"
COMBO_MODELS = [
    "cerebras/gpt-oss-120b",
    "groq/openai/gpt-oss-120b",
    "gemini/gemini-3.8-flash",
    "nvidia/deepseek-ai/deepseek-v4-flash-0731",
    "xr/Penny-Pincher",
]


def read_env(path):
    out = {}
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            for line in fh:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                k, v = line.split("=", 1)
                out[k.strip()] = v.strip().strip('"').strip("'")
    except OSError:
        pass
    return out


class Api:
    def __init__(self, base):
        self.base = base.rstrip("/")
        self.jar = http.cookiejar.CookieJar()
        self.opener = urllib.request.build_opener(
            urllib.request.HTTPCookieProcessor(self.jar)
        )

    def _req(self, method, path, payload=None, timeout=20):
        data = None
        headers = {"Accept": "application/json"}
        if payload is not None:
            data = json.dumps(payload).encode()
            headers["Content-Type"] = "application/json"
        req = urllib.request.Request(self.base + path, data=data,
                                     headers=headers, method=method)
        try:
            with self.opener.open(req, timeout=timeout) as r:
                body = r.read().decode("utf-8", "replace")
                obj = json.loads(body) if body.strip() else {}
                return r.status, (obj if isinstance(obj, dict) else {"data": obj})
        except urllib.error.HTTPError as e:
            body = e.read().decode("utf-8", "replace")
            try:
                parsed = json.loads(body) if body.strip() else {}
            except ValueError:
                parsed = {"raw": body[:200]}
            return e.code, (parsed if isinstance(parsed, dict) else {"data": parsed})
        except Exception as e:  # network / timeout
            return 0, {"error": str(e)}

    def get(self, p):
        return self._req("GET", p)

    def post(self, p, payload):
        return self._req("POST", p, payload)

    def patch(self, p, payload):
        return self._req("PATCH", p, payload)


def wait_health(api, attempts=40):
    for _ in range(attempts):
        code, _ = api.get("/api/health")
        if code == 200:
            return True
        time.sleep(2)
    return False


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default="http://127.0.0.1:20129")
    ap.add_argument("--admin-password-file", required=True)
    ap.add_argument("--env-file", required=True)
    args = ap.parse_args()

    api = Api(args.base)
    if not wait_health(api):
        print("provision: OmniRoute never became healthy; skipping", file=sys.stderr)
        return 0

    try:
        password = open(args.admin_password_file, encoding="utf-8").read().strip()
    except OSError as e:
        print(f"provision: cannot read admin password: {e}", file=sys.stderr)
        return 0
    if not password:
        print("provision: admin password empty; skipping", file=sys.stderr)
        return 0

    code, _ = api.post("/api/auth/login", {"password": password})
    if code != 200:
        print(f"provision: login failed ({code})", file=sys.stderr)
        return 0

    env = read_env(args.env_file)
    upstream_key = env.get("EXTREMEROUTER_API_KEY", "")

    # ── 1. ExtremeRouter node ────────────────────────────────────────────────
    code, data = api.get("/api/provider-nodes")
    nodes = data.get("nodes", []) if code == 200 else []
    node = next((n for n in nodes if n.get("name") == NODE_NAME), None)
    if node is None:
        code, data = api.post("/api/provider-nodes", {
            "name": NODE_NAME,
            "prefix": NODE_PREFIX,
            "apiType": "chat",
            "baseUrl": "http://z0r0.nfp.nix:20128/v1",
            "apiKey": upstream_key,
        })
        node = data.get("node") if code in (200, 201) else None
        print(f"provision: node create -> {code}")
    else:
        print("provision: node exists")

    # ── 2. Connections (node + direct providers) ─────────────────────────────
    code, data = api.get("/api/providers")
    conns = data.get("connections", []) if code == 200 else []
    have = {c.get("provider") for c in conns if c.get("isActive")}

    def ensure_conn(provider, api_key, name, priority):
        if not api_key or provider in have:
            return
        code, _ = api.post("/api/providers", {
            "provider": provider,
            "name": name,
            "authType": "apikey",
            "apiKey": api_key,
            "isActive": True,
            "priority": priority,
        })
        if code in (200, 201):
            # created connections default to inactive
            c2, d2 = api.get("/api/providers")
            for c in d2.get("connections", []):
                if c.get("provider") == provider and not c.get("isActive"):
                    api.patch(f"/api/providers/{c['id']}", {"isActive": True})
            print(f"provision: connection {provider} -> {code}")

    if node:
        ensure_conn(node["id"], upstream_key, NODE_NAME, 10)
    for pid, var in DIRECT_PROVIDERS.items():
        ensure_conn(pid, env.get(var, ""), pid.title(), 5)

    # ── 3. Failover combo ────────────────────────────────────────────────────
    code, data = api.get("/api/combos")
    combos = data.get("combos", []) if code == 200 else []
    if not any(c.get("name") == COMBO_NAME for c in combos):
        code, _ = api.post("/api/combos", {
            "name": COMBO_NAME,
            "models": COMBO_MODELS,
            "strategyConfig": {
                "fallbackStrategy": "fallback",
                "thinking": {"type": "off"},
                "workerCount": 1,
                "enableTelemetry": True,
            },
        })
        print(f"provision: combo create -> {code}")
    else:
        print("provision: combo exists")

    return 0


if __name__ == "__main__":
    sys.exit(main())
