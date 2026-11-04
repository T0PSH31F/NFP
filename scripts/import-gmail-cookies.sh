#!/usr/bin/env bash
# import-gmail-cookies.sh — safely import browser cookies into SOPS for Camofox.
#
# Takes a cookie export (Cookie-Editor JSON *or* Netscape cookies.txt),
# normalizes it to the Camofox /sessions/:userId/cookies schema, encrypts it
# into the NFP SOPS store, verifies the round-trip, and shreds all plaintext.
#
# It never prints a cookie value. Plaintext lives only in /dev/shm (tmpfs).
#
# Usage:
#   ./import-gmail-cookies.sh <account> <cookie-file> [--import] [--dry-run]
#
#   account      wrighterik77 | lovelainautomations
#   cookie-file  path to Cookie-Editor JSON or Netscape cookies.txt
#   --import     after storing, POST the cookies to a running Camofox server
#   --dry-run    normalize + validate only; do not touch SOPS
#
# Env:
#   SOPS_AGE_KEY_FILE   default ~/.config/sops/age/keys.txt
#   NFP_REPO            default ~/Clan/NFP
#   CAMOFOX_URL         default http://127.0.0.1:9377
#   CAMOFOX_API_KEY     else read from /run/secrets/camofox_api_key
#
set -euo pipefail

usage() { sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

ACCOUNT="${1:-}"; INPUT="${2:-}"
[ -n "${ACCOUNT}" ] && [ -n "${INPUT}" ] || usage 1
[ "${ACCOUNT}" = "-h" ] || [ "${ACCOUNT}" = "--help" ] && usage 0

case "${ACCOUNT}" in
  wrighterik77|lovelainautomations) : ;;
  *) echo "ERROR: account must be wrighterik77 or lovelainautomations" >&2; exit 2 ;;
esac

DO_IMPORT=0; DRY_RUN=0
for arg in "${@:3}"; do
  case "$arg" in
    --import) DO_IMPORT=1 ;;
    --dry-run) DRY_RUN=1 ;;
    *) echo "ERROR: unknown option: $arg" >&2; usage 2 ;;
  esac
done

[ -f "$INPUT" ] || { echo "ERROR: cookie file not found: $INPUT" >&2; exit 2; }

REPO="${NFP_REPO:-$HOME/Clan/NFP}"
SOPS_FILE="$REPO/layers/00-cyberia/03-treasure/secrets/external_services.yaml"
KEY="gmail_cookies_${ACCOUNT}"
export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"

[ -f "$SOPS_FILE" ] || { echo "ERROR: SOPS file missing: $SOPS_FILE" >&2; exit 2; }
command -v sops >/dev/null || { echo "ERROR: sops not in PATH" >&2; exit 2; }
command -v python3 >/dev/null || { echo "ERROR: python3 not in PATH" >&2; exit 2; }

umask 077
WORK="$(mktemp -d /dev/shm/gmailcookies.XXXXXX)"
cleanup() {
  find "$WORK" -type f -exec shred -u {} + 2>/dev/null || true
  rm -rf "$WORK"
}
trap cleanup EXIT INT TERM

# ── 1. Normalize + validate ────────────────────────────────────────────────
python3 - "$INPUT" "$WORK/normalized.json" <<'PY'
import json, re, sys

src, dst = sys.argv[1], sys.argv[2]
raw = open(src, encoding="utf-8", errors="replace").read()
text = raw.lstrip()

SAME = {
    "no_restriction": "None", "none": "None", "unspecified": None, "": None,
    "lax": "Lax", "strict": "Strict", None: None,
}

def to_int(v):
    if v in (None, "", 0):
        return -1
    try:
        return int(float(v))
    except Exception:
        return -1

def norm(c):
    name = str(c.get("name", "")).strip()
    value = str(c.get("value", ""))
    domain = str(c.get("domain", "")).strip()
    if not name or not domain:
        return None
    ss = c.get("sameSite")
    ss = SAME.get(ss.lower() if isinstance(ss, str) else None)
    out = {
        "name": name,
        "value": value,
        "domain": domain,
        "path": str(c.get("path") or "/"),
        "expires": to_int(c.get("expires", c.get("expirationDate", c.get("expiration_date")))),
        "httpOnly": bool(c.get("httpOnly", False)),
        "secure": bool(c.get("secure", False)),
    }
    if ss:
        out["sameSite"] = ss
    return out

cookies = []

if text.startswith("[") or text.startswith("{"):
    data = json.loads(raw)
    if isinstance(data, dict):
        data = data.get("cookies", [])
    for c in data:
        n = norm(c)
        if n:
            cookies.append(n)
else:
    # Netscape cookies.txt (tab-separated)
    for line in raw.splitlines():
        http_only = False
        if line.startswith("#HttpOnly_"):
            http_only = True
            line = line[len("#HttpOnly_"):]
        elif line.startswith("#") or not line.strip():
            continue
        parts = line.split("\t")
        if len(parts) < 7:
            continue
        domain, _flag, path, secure, expiry, name, value = parts[:7]
        if not name or not domain:
            continue
        c = {
            "name": name,
            "value": value,
            "domain": domain,
            "path": path or "/",
            "expires": to_int(expiry),
            "httpOnly": http_only,
            "secure": secure.strip().upper() == "TRUE",
        }
        cookies.append(c)

# Keep only Google-family cookies.
cookies = [c for c in cookies if "google" in c["domain"].lower()]

# Dedupe by (name, domain, path), last wins.
seen = {}
for c in cookies:
    seen[(c["name"], c["domain"], c["path"])] = c
cookies = list(seen.values())

if not cookies:
    sys.stderr.write(
        "ERROR: no Google cookies found. Export while logged into "
        "https://mail.google.com and include google.com domains.\n"
    )
    sys.exit(3)

with open(dst, "w", encoding="utf-8") as f:
    json.dump(cookies, f, separators=(",", ":"))

# Report counts only — never values.
domains = sorted({c["domain"] for c in cookies})
sys.stderr.write(f"Normalized {len(cookies)} Google cookies across {len(domains)} domain(s).\n")
PY

echo "Validated: $(python3 -c 'import json,sys;print(len(json.load(open(sys.argv[1]))))' "$WORK/normalized.json") cookies."

if [ "$DRY_RUN" -eq 1 ]; then
  echo "Dry run: SOPS untouched. Normalized JSON left in memory only (shredded on exit)."
  exit 0
fi

# ── 2. Double-encode so SOPS stores a JSON *string*, not a YAML list ───────
python3 - "$WORK/normalized.json" "$WORK/sops-value.json" <<'PY'
import json, sys
obj = json.load(open(sys.argv[1]))
# json.dumps twice -> the SOPS value is a string containing the JSON array.
open(sys.argv[2], "w", encoding="utf-8").write(
    json.dumps(json.dumps(obj, separators=(",", ":")))
)
PY

# ── 3. Encrypt into SOPS (atomic-ish, with rollback) ──────────────────────
cp -f "$SOPS_FILE" "$WORK/sops.bak"

if ! sops set --value-file "$SOPS_FILE" "[\"$KEY\"]" "$WORK/sops-value.json"; then
  echo "ERROR: sops set failed; restoring original." >&2
  cp -f "$WORK/sops.bak" "$SOPS_FILE"
  exit 4
fi

# ── 4. Verify round-trip without printing the value ───────────────────────
sops -d --extract "[\"$KEY\"]" "$SOPS_FILE" > "$WORK/verify.txt" 2>/dev/null || true
COUNT="$(python3 - "$WORK/verify.txt" <<'PY'
import json, sys
raw = open(sys.argv[1], encoding="utf-8", errors="replace").read().strip()
try:
    obj = json.loads(raw)
    if isinstance(obj, str):
        obj = json.loads(obj)
    print(len(obj) if isinstance(obj, list) else 0)
except Exception:
    print(0)
PY
)"

if [ "${COUNT:-0}" -le 0 ]; then
  echo "ERROR: verification failed (decrypted value did not parse). Rolling back." >&2
  cp -f "$WORK/sops.bak" "$SOPS_FILE"
  exit 5
fi

echo "OK: ${COUNT} cookies encrypted into SOPS key '${KEY}'."
echo "File: ${SOPS_FILE}  (commit + 'clan machines update luffy' to apply)"

# ── 5. Optional: import into a running Camofox right now ──────────────────
if [ "$DO_IMPORT" -eq 1 ]; then
  CAMOFOX_URL="${CAMOFOX_URL:-http://127.0.0.1:9377}"
  if [ -z "${CAMOFOX_API_KEY:-}" ] && [ -r /run/secrets/camofox_api_key ]; then
    CAMOFOX_API_KEY="$(cat /run/secrets/camofox_api_key)"
  fi
  if [ -z "${CAMOFOX_API_KEY:-}" ]; then
    echo "WARN: CAMOFOX_API_KEY unset; skipping live import." >&2
  else
    { printf '{"cookies":'; cat "$WORK/normalized.json"; printf '}'; } > "$WORK/body.json"
    if curl -sf -X POST "$CAMOFOX_URL/sessions/${ACCOUNT}/cookies" \
        -H "Authorization: Bearer ${CAMOFOX_API_KEY}" \
        -H "Content-Type: application/json" \
        --data-binary @"$WORK/body.json" >/dev/null; then
      echo "OK: cookies imported into live Camofox session '${ACCOUNT}'."
    else
      echo "WARN: live import failed (is Camofox running on ${CAMOFOX_URL}?)." >&2
    fi
  fi
fi

echo "Done. Plaintext shredded."
