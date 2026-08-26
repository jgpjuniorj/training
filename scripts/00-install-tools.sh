#!/usr/bin/env bash
# installs kubectl, kind, helm into ~/.local/bin (idempotent, no sudo needed)
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
source ./lib.sh

KUBECTL_VERSION="v1.31.0"
KIND_VERSION="v0.24.0"
HELM_VERSION="v3.16.1"

mkdir -p "${BIN_DIR}"
export PATH="${BIN_DIR}:${PATH}"

arch="$(uname -m)"
case "${arch}" in
  x86_64) arch="amd64" ;;
  aarch64|arm64) arch="arm64" ;;
  *) die "unsupported arch: ${arch}" ;;
esac

if ! command -v kubectl >/dev/null 2>&1; then
  log "installing kubectl ${KUBECTL_VERSION}"
  curl -fsSL -o "${BIN_DIR}/kubectl" \
    "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${arch}/kubectl"
  chmod +x "${BIN_DIR}/kubectl"
else
  log "kubectl already installed: $(kubectl version --client --output=yaml 2>/dev/null | grep gitVersion || true)"
fi

if ! command -v kind >/dev/null 2>&1; then
  log "installing kind ${KIND_VERSION}"
  curl -fsSL -o "${BIN_DIR}/kind" \
    "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${arch}"
  chmod +x "${BIN_DIR}/kind"
else
  log "kind already installed: $(kind version)"
fi

if ! command -v helm >/dev/null 2>&1; then
  log "installing helm ${HELM_VERSION}"
  tmp="$(mktemp -d)"
  curl -fsSL -o "${tmp}/helm.tar.gz" \
    "https://get.helm.sh/helm-${HELM_VERSION}-linux-${arch}.tar.gz"
  tar -xzf "${tmp}/helm.tar.gz" -C "${tmp}"
  mv "${tmp}/linux-${arch}/helm" "${BIN_DIR}/helm"
  rm -rf "${tmp}"
else
  log "helm already installed: $(helm version --short)"
fi

log "done. make sure ${BIN_DIR} is on your PATH (add to ~/.bashrc if not)."
if [[ ":${PATH}:" != *":${HOME}/.local/bin:"* ]]; then
  warn "add this to your ~/.bashrc: export PATH=\"\$HOME/.local/bin:\$PATH\""
fi
