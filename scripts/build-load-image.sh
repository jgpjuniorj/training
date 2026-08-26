#!/usr/bin/env bash
# builds the iris-classifier image and loads it straight into the kind nodes
# (no registry needed for this local demo; re-run after any app code change)
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
source ./lib.sh
need_cmd docker
need_cmd kind

IMAGE="iris-classifier:local"

log "building ${IMAGE}"
docker build -t "${IMAGE}" ../apps/iris-classifier

log "loading ${IMAGE} into kind cluster '${CLUSTER_NAME}'"
kind load docker-image "${IMAGE}" --name "${CLUSTER_NAME}"
