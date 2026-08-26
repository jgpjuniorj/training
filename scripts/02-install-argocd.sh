#!/usr/bin/env bash
# installs ArgoCD itself (everything else is GitOps-managed by ArgoCD afterwards)
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
source ./lib.sh
need_cmd kubectl

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

log "installing argocd (official stable manifest)"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

wait_for_deploy argocd argocd-server 300s
wait_for_deploy argocd argocd-repo-server 300s

log "argocd installed. initial admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d
echo
