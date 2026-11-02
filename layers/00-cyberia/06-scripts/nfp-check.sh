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
LOCAL_EVAL=0
REMOTE_HOST=""

# Parse options
while [ $# -gt 0 ]; do
  case "$1" in
  --wait)
    WAIT_MODE=1
    shift
    ;;
  --local)
    LOCAL_EVAL=1
    shift
    ;;
  --remote)
    shift
    REMOTE_HOST="${1:-}"
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

# Optimize Boehm GC for Nix evaluations to prevent memory bloat and avoid tripping OOM
export GC_FREE_SPACE_DIVISOR=1

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
  CURRENT_HOST="$(hostname -s 2>/dev/null || cat /etc/hostname 2>/dev/null || echo "unknown")"

  # Workstation offload: offload to z0r0 or luffy when running on sanji or when requested
  if [ "${LOCAL_EVAL}" = "0" ] && { [ "${CURRENT_HOST}" = "sanji" ] || [ -n "${REMOTE_HOST}" ] || [ "${NFP_REMOTE_EVAL:-0}" = "1" ]; }; then
    CANDIDATES=()
    if [ -n "${REMOTE_HOST}" ]; then
      CANDIDATES=("${REMOTE_HOST}")
    else
      CANDIDATES=("100.64.0.1" "100.64.0.3")
    fi

    CHOSEN_HOST=""
    for cand in "${CANDIDATES[@]}"; do
      if ssh -o ConnectTimeout=2 -o BatchMode=yes "root@${cand}" "true" 2>/dev/null; then
        CHOSEN_HOST="${cand}"
        break
      fi
    done

    if [ -n "${CHOSEN_HOST}" ]; then
      echo "==> Offloading evaluation from workstation (${CURRENT_HOST}) to remote builder (${CHOSEN_HOST})..."
      REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
      REMOTE_DIR="/tmp/nfp-eval"

      ssh "root@${CHOSEN_HOST}" "mkdir -p ${REMOTE_DIR}"
      rsync -az --delete \
        --exclude '.git' \
        --exclude 'result*' \
        --exclude '.direnv' \
        --exclude '.devenv' \
        "${REPO_ROOT}/" "root@${CHOSEN_HOST}:${REMOTE_DIR}/"

      if [ "${TARGET}" = "all" ]; then
        echo "==> Remotely evaluating all fleet machine toplevels (z0r0, luffy, sanji)"
        run_with_timeout ssh "root@${CHOSEN_HOST}" "cd ${REMOTE_DIR} && nix eval --raw path:.#nixosConfigurations.z0r0.config.system.build.toplevel.drvPath >/dev/null"
        run_with_timeout ssh "root@${CHOSEN_HOST}" "cd ${REMOTE_DIR} && nix eval --raw path:.#nixosConfigurations.luffy.config.system.build.toplevel.drvPath >/dev/null"
        run_with_timeout ssh "root@${CHOSEN_HOST}" "cd ${REMOTE_DIR} && nix eval --raw path:.#nixosConfigurations.sanji.config.system.build.toplevel.drvPath >/dev/null"
      else
        echo "==> Remotely evaluating host: ${TARGET}"
        run_with_timeout ssh "root@${CHOSEN_HOST}" "cd ${REMOTE_DIR} && nix eval --raw path:.#nixosConfigurations.${TARGET}.config.system.build.toplevel.drvPath >/dev/null"
      fi
      echo "==> Remote evaluation on ${CHOSEN_HOST} succeeded."
      exit 0
    else
      echo "WARNING: Remote evaluation hosts unreachable; falling back to local evaluation."
    fi
  fi

  if [ "${TARGET}" = "all" ]; then
    echo "==> Evaluating all fleet machine toplevels (z0r0, luffy, sanji)"
    run_with_timeout nix eval --raw .#nixosConfigurations.z0r0.config.system.build.toplevel.drvPath >/dev/null
    run_with_timeout nix eval --raw .#nixosConfigurations.luffy.config.system.build.toplevel.drvPath >/dev/null
    run_with_timeout nix eval --raw .#nixosConfigurations.sanji.config.system.build.toplevel.drvPath >/dev/null
  else
    echo "==> Evaluating host: ${TARGET}"
    run_with_timeout nix eval --raw ".#nixosConfigurations.${TARGET}.config.system.build.toplevel.drvPath" >/dev/null
  fi
  echo "==> Evaluation succeeded."
  ;;
flake)
  CURRENT_HOST="$(hostname -s 2>/dev/null || cat /etc/hostname 2>/dev/null || echo "unknown")"
  if [ "${LOCAL_EVAL}" = "0" ] && { [ "${CURRENT_HOST}" = "sanji" ] || [ -n "${REMOTE_HOST}" ] || [ "${NFP_REMOTE_EVAL:-0}" = "1" ]; }; then
    CANDIDATES=()
    if [ -n "${REMOTE_HOST}" ]; then
      CANDIDATES=("${REMOTE_HOST}")
    else
      CANDIDATES=("100.64.0.1" "100.64.0.3")
    fi

    CHOSEN_HOST=""
    for cand in "${CANDIDATES[@]}"; do
      if ssh -o ConnectTimeout=2 -o BatchMode=yes "root@${cand}" "true" 2>/dev/null; then
        CHOSEN_HOST="${cand}"
        break
      fi
    done

    if [ -n "${CHOSEN_HOST}" ]; then
      echo "==> Offloading nix flake check from workstation (${CURRENT_HOST}) to remote builder (${CHOSEN_HOST})..."
      REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
      REMOTE_DIR="/tmp/nfp-eval"

      ssh "root@${CHOSEN_HOST}" "mkdir -p ${REMOTE_DIR}"
      rsync -az --delete \
        --exclude '.git' \
        --exclude 'result*' \
        --exclude '.direnv' \
        --exclude '.devenv' \
        "${REPO_ROOT}/" "root@${CHOSEN_HOST}:${REMOTE_DIR}/"

      run_with_timeout ssh "root@${CHOSEN_HOST}" "cd ${REMOTE_DIR} && nix flake check"
      echo "==> Remote nix flake check on ${CHOSEN_HOST} succeeded."
      exit 0
    else
      echo "WARNING: Remote evaluation hosts unreachable; falling back to local flake check."
    fi
  fi
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
