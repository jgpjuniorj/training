#!/usr/bin/env bash
# quick smoke test for the iris demo via the istio ingress gateway
set -euo pipefail
HOST_HDR="Host: iris.kiale.local"
BASE="http://localhost:8080"

echo "--- healthz ---"
curl -s -H "${HOST_HDR}" "${BASE}/healthz"; echo

for f in p1 p2 p3; do
  echo "--- predict ${f} ---"
  curl -s -H "${HOST_HDR}" -X POST "${BASE}/predict" \
    -H 'Content-Type: application/json' \
    --data-binary "@/tmp/${f}.json"
  echo
done
