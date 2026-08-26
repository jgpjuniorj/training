#!/usr/bin/env bash
# shared helpers sourced by every script in this folder
set -euo pipefail

CLUSTER_NAME="kiale"
BIN_DIR="${HOME}/.local/bin"
PID_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.pids"

log()  { echo -e "\033[1;36m[kiale]\033[0m $*"; }
warn() { echo -e "\033[1;33m[kiale]\033[0m $*" >&2; }
die()  { echo -e "\033[1;31m[kiale]\033[0m $*" >&2; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing command: $1 (run scripts/00-install-tools.sh)"
}

wait_for_deploy() {
  local ns="$1" name="$2" timeout="${3:-300s}"
  log "waiting for deployment ${name} in ns ${ns} (timeout ${timeout})"
  kubectl -n "${ns}" rollout status "deploy/${name}" --timeout "${timeout}"
}
