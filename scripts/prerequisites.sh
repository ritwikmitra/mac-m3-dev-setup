#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/common.sh"

log "Checking macOS prerequisites"

if ! xcode-select -p >/dev/null 2>&1 || ! /usr/bin/xcrun --find git >/dev/null 2>&1; then
  die "Xcode Command Line Tools are required. Run ./setup.sh --xcode, complete Apple's installer, then rerun ./setup.sh."
fi
