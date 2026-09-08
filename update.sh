#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT_DIR/scripts/common.sh"

require_apple_silicon

log "Updating Homebrew"
brew update
brew upgrade
brew upgrade --cask --greedy || true
brew cleanup

log "Updating mise"
export PATH="$HOME/.local/bin:$PATH"
if command -v mise >/dev/null 2>&1; then
  mise self-update || true
  mise upgrade || true
fi

log "Updating globally installed npm AI tooling"
if command -v npm >/dev/null 2>&1; then
  npm install -g @google/gemini-cli@latest
fi

log "Updating Hugging Face CLI"
if command -v hf >/dev/null 2>&1; then
  hf update || true
fi

log "Running health checks"
command -v git >/dev/null && git --version || true
command -v mise >/dev/null && mise --version || true
command -v java >/dev/null && java -version 2>&1 | head -1 || true
command -v go >/dev/null && go version || true
command -v python >/dev/null && python --version || true
command -v node >/dev/null && node --version || true
command -v claude >/dev/null && claude --version || true
command -v codex >/dev/null && codex --version || true
command -v gemini >/dev/null && gemini --version || true
command -v hf >/dev/null && hf --version || true

log "Update complete"
