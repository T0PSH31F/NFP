#!/usr/bin/env bash
# nfp-check — Guarded Nix build/eval/flake coordinator for NFP
# Prevents concurrent agent Nix evaluations from overloading system resources.
set -euo pipefail

LOCK_DIR="${XDG_RUNTIME_DIR:-/tmp}/nfp-nix"
LOCK_FILE="${LOCK_DIR}/nfp-check.lock"
META_FILE="${LOCK_DIR}/nfp-check.meta"

mkdir -p "${LOCK_DIR}"

MODE="eval"
WAIT_MODE=0

# Parse options
while [ $# -gt 0 ]; do
  case "$1" in
  --wait)
    WAIT_MODE=1
    shift
    ;;
  status | static | eval | flake | build)
    MODE="$1"
    shift
    break
    ;;
  *)
    break
    ;;
  esac
done

# Detect nested invocation
if [ "${NFP_CHECK_HELD:-0}" = "1" ]; then
  echo "ERROR: Nested nfp-check invocation detected in PID $$!" >&2
  exit 43
fi

# Function to get start time of a PID
get_pid_starttime() {
  local pid="$1"
  if [ -d "/proc/${pid}" ]; then
    stat -c %Y "/proc/${pid}" 2>/dev/null || echo "0"
  else
    echo "0"
  fi
}

get_lock_owner() {
  if [ -f "${META_FILE}" ]; then
    cat "${META_FILE}" 2>/dev/null || echo "No metadata file content"
  else
    echo "No metadata file present"
  fi
}

if [ "${MODE}" = "status" ]; then
  exec 200>"${LOCK_FILE}"
  if flock -n 200; then
    echo "Lock Status: FREE"
    exec 200>&-
  else
    echo "Lock Status: HELD"
    echo "Owner Metadata:"
    get_lock_owner
  fi
  free -h
  exit 0
fi

# Determine timeout based on mode
case "${MODE}" in
static)
  TIMEOUT=300 # 5 min
  ;;
eval)
  TIMEOUT=600 # 10 min
  ;;
flake | build)
  TIMEOUT=1800 # 30 min
  ;;
*)
  TIMEOUT=600
  ;;
esac

exec 200>"${LOCK_FILE}"

# Attempt to acquire lock BEFORE writing metadata
if [ "${WAIT_MODE}" = "1" ]; then
  if ! flock -w 30 200; then
    echo "ERROR: Lock acquisition timed out (30s)." >&2
    echo "Owner Metadata:" >&2
    get_lock_owner >&2
    exec 200>&- 2>/dev/null || true
    exit 42
  fi
else
  if ! flock -n 200; then
    echo "ERROR: Lock contention — another Nix verification is currently running." >&2
    echo "Owner Metadata:" >&2
    get_lock_owner >&2
    exec 200>&- 2>/dev/null || true
    exit 42
  fi
fi

# Flock acquired successfully! Record metadata for the current running process
START_TIME=$(get_pid_starttime $$)
cat <<EOF >"${META_FILE}"
PID: $$
PPID: $PPID
StartTime: ${START_TIME}
Timestamp: $(date -Iseconds)
Cwd: $(pwd)
Command: nfp-check ${MODE} $*
EOF

export NFP_CHECK_HELD=1

cleanup() {
  rm -f "${META_FILE}"
  exec 200>&- 2>/dev/null || true
}
trap cleanup EXIT INT TERM

run_with_timeout() {
  local cmd=("$@")
  timeout --foreground --kill-after=10s "${TIMEOUT}s" "${cmd[@]}"
}

case "${MODE}" in
static)
  echo "==> Running static formatting and linter checks"
  nix fmt -- --fail-on-change
  deadnix --fail . || echo "WARNING: deadnix found unused code"
  statix check . || echo "WARNING: statix check reported warnings (baseline debt)"
  ;;
eval)
  TARGET="${1:-all}"
  if [ "${TARGET}" = "all" ]; then
    echo "==> Evaluating all fleet machine toplevels (z0r0, luffy, nami)"
    run_with_timeout nix eval --raw .#nixosConfigurations.z0r0.config.system.build.toplevel.drvPath >/dev/null
    run_with_timeout nix eval --raw .#nixosConfigurations.luffy.config.system.build.toplevel.drvPath >/dev/null
    run_with_timeout nix eval --raw .#nixosConfigurations.nami.config.system.build.toplevel.drvPath >/dev/null
  else
    echo "==> Evaluating host: ${TARGET}"
    run_with_timeout nix eval --raw ".#nixosConfigurations.${TARGET}.config.system.build.toplevel.drvPath" >/dev/null
  fi
  echo "==> Evaluation succeeded."
  ;;
flake)
  echo "==> Running nix flake check"
  run_with_timeout nix flake check
  ;;
build)
  ATTR="${1:-.#nixosConfigurations.z0r0.config.system.build.toplevel}"
  echo "==> Building attribute: ${ATTR}"
  run_with_timeout nix build "${ATTR}"
  ;;
*)
  echo "Usage: nfp-check [--wait] {status|static|eval [host]|flake|build <attr>}" >&2
  exit 1
  ;;
esac
