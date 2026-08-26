#!/usr/bin/env bash
# applies the app-of-apps root Application; ArgoCD takes it from there
# (istio, prometheus/grafana, kiali and the iris-classifier demo all sync automatically)
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
source ./lib.sh
need_cmd kubectl

log "applying app-of-apps root Application"
kubectl apply -f ../gitops/argocd/root.yaml

log "root app applied. ArgoCD will now reconcile every child Application."
log "watch progress with: kubectl -n argocd get applications -w"
