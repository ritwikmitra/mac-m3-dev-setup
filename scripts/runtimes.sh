#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/common.sh"

log "Installing mise"
if ! command -v mise >/dev/null 2>&1; then
  curl https://mise.run | sh
fi
export PATH="$HOME/.local/bin:$PATH"

eval "$(mise activate zsh)" 2>/dev/null || true

log "Configuring latest stable development runtimes"
mise use --global java@25
after_java="$(mise latest java@25 2>/dev/null || true)"
mise use --global go@latest
mise use --global python@latest
# Node: latest LTS rather than bleeding-edge current.
mise use --global node@lts
mise use --global maven@latest
mise use --global gradle@latest

mise doctor || true
