#!/usr/bin/env bash
# opens background port-forwards for every UI/endpoint used in the demo
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
source ./lib.sh
need_cmd kubectl
mkdir -p "${PID_DIR}"

start_pf() {
  local name="$1" ns="$2" svc="$3" ports="$4"
  if [[ -f "${PID_DIR}/${name}.pid" ]] && kill -0 "$(cat "${PID_DIR}/${name}.pid")" 2>/dev/null; then
    log "${name} port-forward already running (pid $(cat "${PID_DIR}/${name}.pid"))"
    return
  fi
  nohup kubectl -n "${ns}" port-forward "svc/${svc}" "${ports}" \
    >"${PID_DIR}/${name}.log" 2>&1 &
  echo $! >"${PID_DIR}/${name}.pid"
  log "${name}: forwarding ${ports} (pid $!)"
}

start_pf argocd    argocd        argocd-server                     8081:443
start_pf kiali     istio-system  kiali                             20001:20001
start_pf grafana   monitoring    kube-prometheus-stack-grafana     3000:80
start_pf prometheus monitoring  kube-prometheus-stack-prometheus   9090:9090
start_pf iris-app  istio-system  istio-ingressgateway              8080:80

cat <<EOF

  ArgoCD    : https://localhost:8081  (user: admin, password: see scripts/02-install-argocd.sh output)
  Kiali     : http://localhost:20001
  Grafana   : http://localhost:3000   (user: admin / prom-operator)
  Prometheus: http://localhost:9090
  Iris demo : http://localhost:8080

  stop all with: ./scripts/stop-port-forward.sh
EOF
