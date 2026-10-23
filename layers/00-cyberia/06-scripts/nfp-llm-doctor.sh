#!/usr/bin/env bash
# nfp-llm-doctor — Fleet LLM Gateway & CLI Harness Discovery Diagnostic
# Tests model discovery, authentication headers, and endpoint health for:
#   1. Kong Gateway (apikey, Authorization: Bearer, x-api-key)
#   2. Pi Coding Agent (~/.pi/agent/models.json + pi auth check + live /v1/models)
#   3. Hermes Agent (/etc/hermes/config.yaml + ~/.hermes/config.yaml + live /v1/models)
#   4. OpenCode (~/.config/opencode/opencode.json + opencode models + live /v1/models)
#   5. Claude Code (~/.config/claude/settings.json + x-api-key /v1/models & /v1/messages)
#   6. Codex CLI (~/.config/codex/config.toml + codex doctor + /v1/models & /v1/responses)
# Exits non-zero if any harness fails discovery.

set -euo pipefail

PATH="/run/current-system/sw/bin:/etc/profiles/per-user/${USER:-t0psh31f}/bin:$HOME/.local/bin:$PATH"
PYTHON_BIN="$(command -v python3 || echo /nix/store/lb41b0anx1f98y9y5s9mdv97gjgsq740-python3-3.14.7/bin/python3)"

KONG_URL="${NFP_KONG_URL:-http://127.0.0.1:8090}"
if ! curl -s --max-time 2 "${KONG_URL}/health" >/dev/null 2>&1; then
  KONG_URL="http://sanji.nfp.nix:8090"
fi

SECRETS_DIR="${HOME}/.config/sops-nix/secrets"
SYSTEM_SECRETS_DIR="/run/secrets"

read_secret() {
  local name="$1"
  if [ -r "${SECRETS_DIR}/${name}" ]; then
    tr -d '\r\n' <"${SECRETS_DIR}/${name}"
  elif [ -r "${SYSTEM_SECRETS_DIR}/${name}" ]; then
    tr -d '\r\n' <"${SYSTEM_SECRETS_DIR}/${name}"
  else
    echo ""
  fi
}

FAILURES=0
PASSES=0

pass() {
  printf "  \033[32m[PASS]\033[0m %-18s %s\n" "$1" "$2"
  PASSES=$((PASSES + 1))
}

fail() {
  printf "  \033[31m[FAIL]\033[0m %-18s %s\n" "$1" "$2"
  FAILURES=$((FAILURES + 1))
}

probe_models() {
  local header_name="$1"
  local header_val="$2"
  local url="${3:-${KONG_URL}/v1/models}"
  "$PYTHON_BIN" - "$url" "$header_name" "$header_val" <<'PYEOF'
import json, sys, urllib.request, urllib.error
url, hname, hval = sys.argv[1], sys.argv[2], sys.argv[3]
req = urllib.request.Request(url, headers={hname: hval})
try:
    with urllib.request.urlopen(req, timeout=8) as r:
        data = json.loads(r.read().decode("utf-8", "replace"))
        models = data.get("data", [])
        print(f"200:{len(models)}")
except urllib.error.HTTPError as e:
    print(f"{e.code}:0")
except Exception as e:
    print(f"ERR:0:{e}")
PYEOF
}

probe_route_exists() {
  local url="$1"
  local header_name="$2"
  local header_val="$3"
  "$PYTHON_BIN" - "$url" "$header_name" "$header_val" <<'PYEOF'
import sys, urllib.request, urllib.error
url, hname, hval = sys.argv[1], sys.argv[2], sys.argv[3]
req = urllib.request.Request(url, data=b"{}", headers={hname: hval, "Content-Type": "application/json"}, method="POST")
try:
    with urllib.request.urlopen(req, timeout=8) as r:
        print(r.status)
except urllib.error.HTTPError as e:
    body = e.read().decode("utf-8", "replace")
    if e.code == 404 and "no Route matched" in body:
        print("404_KONG")
    else:
        print(e.code)
except Exception as e:
    print(f"ERR:{e}")
PYEOF
}

echo "========================================================================"
echo " NFP LLM Doctor — Gateway & Harness Discovery Verification"
echo " Gateway: ${KONG_URL}"
echo "========================================================================"

# ── 0. Kong Header Normalization Check ─────────────────────────────────
KEY_HERMES="$(read_secret kong_key_hermes)"
if [ -z "$KEY_HERMES" ]; then
  fail "kong-secrets" "Missing kong_key_hermes in ${SECRETS_DIR} or ${SYSTEM_SECRETS_DIR}"
else
  RES_APIKEY="$(probe_models "apikey" "$KEY_HERMES")"
  RES_BEARER="$(probe_models "Authorization" "Bearer $KEY_HERMES")"
  RES_XAPI="$(probe_models "x-api-key" "$KEY_HERMES")"
  C_APIKEY="${RES_APIKEY#*:}"
  C_BEARER="${RES_BEARER#*:}"
  C_XAPI="${RES_XAPI#*:}"
  if [[ $RES_APIKEY == 200:* && ${C_APIKEY%%:*} -gt 0 && $RES_BEARER == 200:* && ${C_BEARER%%:*} -gt 0 && $RES_XAPI == 200:* && ${C_XAPI%%:*} -gt 0 ]]; then
    pass "kong-gateway" "apikey=${C_APIKEY} models, Bearer=${C_BEARER} models, x-api-key=${C_XAPI} models"
  else
    fail "kong-gateway" "Header matrix failed: apikey=${RES_APIKEY}, Bearer=${RES_BEARER}, x-api-key=${RES_XAPI}"
  fi
fi

# ── 1. Pi Coding Agent ─────────────────────────────────────────────────
KEY_PI="$(read_secret kong_key_pi)"
PI_MODELS_FILE="${HOME}/.pi/agent/models.json"
if [ ! -f "$PI_MODELS_FILE" ]; then
  fail "pi" "Missing ${PI_MODELS_FILE}"
elif [ -z "$KEY_PI" ]; then
  fail "pi" "Missing kong_key_pi secret"
else
  PI_CFG_COUNT="$(
    "$PYTHON_BIN" - "$PI_MODELS_FILE" <<'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
    d = json.load(f)
p = d.get("providers", {}).get("kong", {})
print(len(p.get("models", [])) if p.get("api") == "openai-completions" else 0)
PYEOF
  )"
  PI_AUTH_OUT="$(pi auth check --provider kong --json 2>/dev/null || echo '{}')"
  PI_LIVE="$(probe_models "Authorization" "Bearer $KEY_PI")"
  PI_LIVE_COUNT="${PI_LIVE#*:}"
  if [[ $PI_CFG_COUNT -gt 0 && $PI_AUTH_OUT == *'"status":"ready"'* && $PI_LIVE == 200:* && ${PI_LIVE_COUNT%%:*} -gt 0 ]]; then
    pass "pi" "models.json=${PI_CFG_COUNT} models, auth=ready, Kong /v1/models=${PI_LIVE_COUNT} models"
  else
    fail "pi" "cfg_models=${PI_CFG_COUNT}, auth=${PI_AUTH_OUT}, live=${PI_LIVE}"
  fi
fi

# ── 2. Hermes Agent ────────────────────────────────────────────────────
KEY_HERMES_VOICE="$(read_secret kong_key_hermes_voice)"
HERMES_CFG="/etc/hermes/config.yaml"
if [ -f "${HOME}/.hermes/config.yaml" ]; then
  HERMES_CFG="${HOME}/.hermes/config.yaml"
fi
if [ -z "$KEY_HERMES" ] || [ -z "$KEY_HERMES_VOICE" ]; then
  fail "hermes" "Missing kong_key_hermes or kong_key_hermes_voice"
else
  H_LIVE="$(probe_models "Authorization" "Bearer $KEY_HERMES")"
  HV_LIVE="$(probe_models "Authorization" "Bearer $KEY_HERMES_VOICE")"
  H_COUNT="${H_LIVE#*:}"
  HV_COUNT="${HV_LIVE#*:}"
  if [[ $H_LIVE == 200:* && ${H_COUNT%%:*} -gt 0 && $HV_LIVE == 200:* && ${HV_COUNT%%:*} -gt 0 ]]; then
    pass "hermes" "config=${HERMES_CFG}, hermes=${H_COUNT} models, hermes-voice=${HV_COUNT} models"
  else
    fail "hermes" "hermes=${H_LIVE}, hermes-voice=${HV_LIVE}"
  fi
fi

# ── 3. OpenCode ────────────────────────────────────────────────────────
KEY_OPENCODE="$(read_secret kong_key_opencode)"
OPENCODE_CFG="${HOME}/.config/opencode/opencode.json"
if [ ! -f "$OPENCODE_CFG" ]; then
  fail "opencode" "Missing ${OPENCODE_CFG}"
elif [ -z "$KEY_OPENCODE" ]; then
  fail "opencode" "Missing kong_key_opencode"
else
  OC_CFG_COUNT="$(
    "$PYTHON_BIN" - "$OPENCODE_CFG" <<'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
    d = json.load(f)
p = d.get("provider", {}).get("kong", {})
print(len(p.get("models", {})))
PYEOF
  )"
  OC_LIVE="$(probe_models "Authorization" "Bearer $KEY_OPENCODE")"
  OC_LIVE_COUNT="${OC_LIVE#*:}"
  if [[ $OC_CFG_COUNT -gt 0 && $OC_LIVE == 200:* && ${OC_LIVE_COUNT%%:*} -gt 0 ]]; then
    pass "opencode" "opencode.json kong=${OC_CFG_COUNT} models, Kong /v1/models=${OC_LIVE_COUNT} models"
  else
    fail "opencode" "cfg=${OC_CFG_COUNT}, live=${OC_LIVE}"
  fi
fi

# ── 4. Claude Code ─────────────────────────────────────────────────────
KEY_CLAUDE="$(read_secret kong_key_claude_code)"
CLAUDE_CFG="${HOME}/.config/claude/settings.json"
if [ ! -f "$CLAUDE_CFG" ]; then
  fail "claude-code" "Missing ${CLAUDE_CFG}"
elif [ -z "$KEY_CLAUDE" ]; then
  fail "claude-code" "Missing kong_key_claude_code"
else
  CC_DISCOVERY="$(
    "$PYTHON_BIN" - "$CLAUDE_CFG" <<'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
    d = json.load(f)
env = d.get("env", {})
print("1" if env.get("CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY") == "1" and env.get("ANTHROPIC_BASE_URL") else "0")
PYEOF
  )"
  CC_MODELS="$(probe_models "x-api-key" "$KEY_CLAUDE")"
  CC_MODELS_COUNT="${CC_MODELS#*:}"
  CC_MSG_ROUTE="$(probe_route_exists "${KONG_URL}/v1/messages" "x-api-key" "$KEY_CLAUDE")"
  if [[ $CC_DISCOVERY == "1" && $CC_MODELS == 200:* && ${CC_MODELS_COUNT%%:*} -gt 0 && $CC_MSG_ROUTE != "404_KONG" && $CC_MSG_ROUTE != "401" && $CC_MSG_ROUTE != ERR* ]]; then
    pass "claude-code" "gateway_discovery=1, x-api-key /v1/models=${CC_MODELS_COUNT} models, /v1/messages route=${CC_MSG_ROUTE}"
  else
    fail "claude-code" "discovery=${CC_DISCOVERY}, models=${CC_MODELS}, /v1/messages=${CC_MSG_ROUTE}"
  fi
fi

# ── 5. Codex CLI ───────────────────────────────────────────────────────
KEY_CODEX="$(read_secret kong_key_codex)"
CODEX_CFG="${HOME}/.config/codex/config.toml"
if [ ! -f "$CODEX_CFG" ]; then
  fail "codex" "Missing ${CODEX_CFG}"
elif [ -z "$KEY_CODEX" ]; then
  fail "codex" "Missing kong_key_codex"
else
  HAS_RESPONSES="$(grep -c 'wire_api = "responses"' "$CODEX_CFG" || true)"
  CX_MODELS="$(probe_models "Authorization" "Bearer $KEY_CODEX")"
  CX_MODELS_COUNT="${CX_MODELS#*:}"
  CX_RESP_ROUTE="$(probe_route_exists "${KONG_URL}/v1/responses" "Authorization" "Bearer $KEY_CODEX")"
  if [[ $HAS_RESPONSES -gt 0 && $CX_MODELS == 200:* && ${CX_MODELS_COUNT%%:*} -gt 0 && $CX_RESP_ROUTE != "404_KONG" && $CX_RESP_ROUTE != "401" && $CX_RESP_ROUTE != ERR* ]]; then
    pass "codex" "wire_api=responses, Bearer /v1/models=${CX_MODELS_COUNT} models, /v1/responses route=${CX_RESP_ROUTE}"
  else
    fail "codex" "wire_api_responses=${HAS_RESPONSES}, models=${CX_MODELS}, /v1/responses=${CX_RESP_ROUTE}"
  fi
fi

echo "------------------------------------------------------------------------"
echo " Summary: ${PASSES} passed, ${FAILURES} failed"
echo "========================================================================"

if [ "$FAILURES" -gt 0 ]; then
  exit 1
fi
exit 0
