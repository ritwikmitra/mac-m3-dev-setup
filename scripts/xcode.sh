#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/common.sh"

if xcode-select -p >/dev/null 2>&1 && /usr/bin/xcrun --find git >/dev/null 2>&1; then
  log "Xcode Command Line Tools are already installed: $(xcode-select -p)"
  exit 0
fi

log "Launching Apple's Xcode Command Line Tools installer"
xcode-select --install || true

warn "Apple's installer runs interactively. Complete the installation, then rerun ./setup.sh."
exit 2
