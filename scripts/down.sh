#!/usr/bin/env bash
# tears down the local kind cluster completely (all namespaces, all state)
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
source ./lib.sh
need_cmd kind

./stop-port-forward.sh || true

log "deleting kind cluster '${CLUSTER_NAME}'"
kind delete cluster --name "${CLUSTER_NAME}"
