#!/usr/bin/env bash
# runs the whole environment end-to-end: tools -> cluster -> argocd -> gitops apps
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
source ./lib.sh

./00-install-tools.sh
export PATH="${BIN_DIR}:${PATH}"
./01-create-cluster.sh
./build-load-image.sh
./02-install-argocd.sh
./03-bootstrap-apps.sh

log "bootstrap requested. platform components (istio, prometheus, grafana, kiali) and"
log "the iris-classifier demo will keep syncing in the background as ArgoCD pulls images"
log "and CRDs settle. check status with: kubectl -n argocd get applications"
log ""
log "once everything shows 'Synced/Healthy', run: ./scripts/port-forward.sh"
