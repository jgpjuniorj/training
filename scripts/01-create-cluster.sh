#!/usr/bin/env bash
# creates (or reuses) the local kind cluster used for the whole demo
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
source ./lib.sh
need_cmd kind
need_cmd kubectl

if kind get clusters 2>/dev/null | grep -qx "${CLUSTER_NAME}"; then
  log "kind cluster '${CLUSTER_NAME}' already exists, reusing it"
else
  log "creating kind cluster '${CLUSTER_NAME}'"
  kind create cluster --name "${CLUSTER_NAME}" --config ../cluster/kind-config.yaml
fi

kubectl cluster-info --context "kind-${CLUSTER_NAME}"
