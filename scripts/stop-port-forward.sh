#!/usr/bin/env bash
# kills every background port-forward started by port-forward.sh
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
source ./lib.sh

if [[ ! -d "${PID_DIR}" ]]; then
  exit 0
fi

for pidfile in "${PID_DIR}"/*.pid; do
  [[ -e "${pidfile}" ]] || continue
  pid="$(cat "${pidfile}")"
  name="$(basename "${pidfile}" .pid)"
  if kill -0 "${pid}" 2>/dev/null; then
    kill "${pid}"
    log "stopped ${name} (pid ${pid})"
  fi
  rm -f "${pidfile}"
done
