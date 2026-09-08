#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/common.sh"

log "Applying developer-friendly macOS settings"

# Finder
/usr/bin/defaults write com.apple.finder AppleShowAllFiles -bool true
/usr/bin/defaults write NSGlobalDomain AppleShowAllExtensions -bool true
/usr/bin/defaults write com.apple.finder ShowPathbar -bool true
/usr/bin/defaults write com.apple.finder ShowStatusBar -bool true
/usr/bin/defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Screenshots: keep them out of the desktop.
mkdir -p "$HOME/Pictures/Screenshots"
/usr/bin/defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"

# Dock: less clutter, no automatic rearrangement. Existing user app choices are preserved.
/usr/bin/defaults write com.apple.dock autohide -bool true
/usr/bin/defaults write com.apple.dock show-recents -bool false

# Save panels / Finder use full path in title where supported.
/usr/bin/defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
/usr/bin/defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
/usr/bin/defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Restart affected user applications.
killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true

log "macOS settings applied"
