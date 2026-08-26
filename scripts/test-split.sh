#!/usr/bin/env bash
# calls /healthz N times through the gateway to observe the v1/v2 weighted split
set -euo pipefail
N="${1:-12}"
for i in $(seq 1 "${N}"); do
  curl -s -H "Host: iris.kiale.local" http://localhost:8080/healthz
  echo
done
