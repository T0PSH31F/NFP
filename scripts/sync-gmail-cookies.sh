#!/usr/bin/env bash
# sync-gmail-cookies.sh — extract Google session cookies straight from a local
# Chrome/Brave profile and encrypt them into SOPS for Camofox. No manual export.
#
# Usage:
#   ./sync-gmail-cookies.sh <account> <browser> [--profile NAME] [--dry-run] [--import]
#
#   account   wrighterik77 | lovelainautomations
#   browser   chrome | brave
#
# Handles Chrome OSCrypt v10 (PBKDF2 "peanuts") and v11 (OS keyring secret
# fetched via secret-tool). Plaintext only ever touches /dev/shm (tmpfs) and is
# shredded on exit. Cookie values are never printed.
set -euo pipefail

ACCOUNT="${1:-}"
BROWSER="${2:-}"
[ -n "$ACCOUNT" ] && [ -n "$BROWSER" ] || {
  sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
  exit 1
}
case "$ACCOUNT" in wrighterik77 | lovelainautomations) ;; *)
  echo "bad account" >&2
  exit 2
  ;;
esac
case "$BROWSER" in chrome | brave) ;; *)
  echo "bad browser" >&2
  exit 2
  ;;
esac

PROFILE="Default"
DRY=0
IMP=0
shift 2
while [ $# -gt 0 ]; do
  case "$1" in
  --profile)
    PROFILE="$2"
    shift 2
    ;;
  --dry-run)
    DRY=1
    shift
    ;;
  --import)
    IMP=1
    shift
    ;;
  *)
    echo "unknown option: $1" >&2
    exit 2
    ;;
  esac
done

case "$BROWSER" in
chrome) ROOT="$HOME/.config/google-chrome" ;;
brave) ROOT="$HOME/.config/BraveSoftware/Brave-Browser" ;;
esac
DB="$ROOT/$PROFILE/Cookies"
[ -f "$DB" ] || {
  echo "ERROR: no cookie DB at $DB" >&2
  exit 3
}

# Pick an interpreter that actually has `cryptography` (the bare system
# python3 does not; the Hermes agent venv does).
PY=""
for cand in python3 python3.12 /nix/store/*-hermes-agent-env/bin/python3.12; do
  if [ -x "$(command -v "$cand" 2>/dev/null || echo "$cand")" ] 2>/dev/null; then
    if "$cand" -c 'import cryptography' >/dev/null 2>&1; then
      PY="$cand"
      break
    fi
  fi
done
[ -n "$PY" ] || {
  echo "ERROR: no Python with 'cryptography' found" >&2
  exit 3
}

umask 077
WORK="$(mktemp -d /dev/shm/gmailcookies.XXXXXX)"
cleanup() {
  find "$WORK" -type f -exec shred -u {} + 2>/dev/null || true
  rm -rf "$WORK"
}
trap cleanup EXIT INT TERM

"$PY" - "$DB" "$BROWSER" "$WORK/cookies.json" <<'PY'
import sqlite3, sys, os, hashlib, subprocess, json
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes

db, browser, dst = sys.argv[1], sys.argv[2], sys.argv[3]

def ring_secret():
    try:
        r = subprocess.run(["secret-tool","lookup","application",browser],
                           capture_output=True, timeout=10)
        s = r.stdout.rstrip(b"\n")
        return s or None
    except Exception:
        return None

def mk(pw): return hashlib.pbkdf2_hmac("sha1", pw, b"saltysalt", 1, 16)

def decrypt(enc, host, key):
    if enc[:3] not in (b"v10", b"v11"): return None
    ct = enc[3:]
    if len(ct) % 16: return None
    d = Cipher(algorithms.AES(key), modes.CBC(b" " * 16)).decryptor()
    pt = d.update(ct) + d.finalize()
    if pt:
        pad = pt[-1]
        if 0 < pad <= 16: pt = pt[:-pad]
    if len(pt) > 32 and pt[:32] == hashlib.sha256(host.encode()).digest():
        pt = pt[32:]
    try: return pt.decode("utf-8")
    except Exception: return None

keys = [mk(b"peanuts")]
rs = ring_secret()
if rs: keys.insert(0, mk(rs))  # v11 first; peanuts still tried as fallback

con = sqlite3.connect(f"file:{db}?mode=ro&immutable=1", uri=True)
rows = con.execute(
  "select name,host_key,path,encrypted_value,is_secure,is_httponly,is_persistent "
  "from cookies where host_key like '%google.com'"
).fetchall()
con.close()

out = []
for name, host, path, enc, secure, httponly, persistent in rows:
    val = None
    for k in keys:
        val = decrypt(enc, host, k)
        if val is not None: break
    if val is None: continue
    out.append({
        "name": name, "value": val, "domain": host, "path": path or "/",
        "expires": -1, "httpOnly": bool(httponly), "secure": bool(secure),
    })

seen = {}
for c in out:
    seen[(c["name"], c["domain"], c["path"])] = c
out = list(seen.values())

if not out:
    sys.stderr.write("ERROR: no decryptable Google cookies found in %s\n" % db)
    sys.exit(4)

json.dump(out, open(dst, "w"), separators=(",", ":"))
sys.stderr.write("Decrypted %d Google cookies from %s (%s).\n" % (len(out), browser, os.path.basename(os.path.dirname(db))))
PY

if [ "$DRY" -eq 1 ]; then
  echo "Dry run: decrypted OK, SOPS untouched."
  exit 0
fi

ARGS=("$ACCOUNT" "$WORK/cookies.json")
[ "$IMP" -eq 1 ] && ARGS+=(--import)
"$(dirname "$0")/import-gmail-cookies.sh" "${ARGS[@]}"
