#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/common.sh"
SKIP_AI="${1:-false}"

log "Installing GUI applications via Homebrew Cask"

# Casks are preferred where they are maintained and support native auto-updates.
# Authentication/licensing remains a first-launch concern.
install_app_cask() {
  local cask="$1"
  local app_path="$2"

  if brew list --cask "$cask" >/dev/null 2>&1; then
    log "Cask $cask is already installed"
  elif [[ -e "$app_path" ]]; then
    warn "$app_path already exists; leaving it unchanged and skipping cask $cask."
  else
    brew_install_casks "$cask"
  fi
}

install_cli_cask() {
  local cask="$1"
  local command="$2"

  if brew list --cask "$cask" >/dev/null 2>&1; then
    log "Cask $cask is already installed"
  elif command -v "$command" >/dev/null 2>&1; then
    warn "Command $command already exists; leaving it unchanged and skipping cask $cask."
  else
    brew_install_casks "$cask"
  fi
}

app_casks=(
  intellij-idea /Applications/IntelliJ\ IDEA.app
  goland /Applications/GoLand.app
  pycharm /Applications/PyCharm.app
  datagrip /Applications/DataGrip.app
  visual-studio-code /Applications/Visual\ Studio\ Code.app
  docker-desktop /Applications/Docker.app
  warp /Applications/Warp.app
  postman /Applications/Postman.app
  google-chrome /Applications/Google\ Chrome.app
  zoom /Applications/zoom.us.app
  microsoft-teams /Applications/Microsoft\ Teams.app
  kde-connect /Applications/KDE\ Connect.app
  raycast /Applications/Raycast.app
  stats /Applications/Stats.app
  ollama-app /Applications/Ollama.app
  lm-studio /Applications/LM\ Studio.app
  devutils /Applications/DevUtils.app
  antinote /Applications/Antinote.app
)

for ((i = 0; i < ${#app_casks[@]}; i += 2)); do
  install_app_cask "${app_casks[i]}" "${app_casks[i + 1]}"
done

if [[ "$SKIP_AI" != true ]]; then
  install_app_cask chatgpt /Applications/ChatGPT.app
  install_app_cask google-gemini /Applications/Gemini.app
  # claude-code is managed earlier by developer-tools.sh, where its `claude`
  # command is preflighted before any cask installation is attempted.
  install_cli_cask codex codex
fi

# SafeInCloud was renamed to Safe and its vendor DMG is no longer published.
# App Store installation requires the user's Apple Account, so keep this
# authentication-dependent action outside the non-interactive bootstrap.
if [[ ! -d "/Applications/Safe.app" ]] && [[ ! -d "/Applications/SafeInCloud.app" ]]; then
  warn "Install Safe from the Mac App Store after setup: https://apps.apple.com/app/id883070818"
else
  log "Safe is already installed"
fi

# The Google Gemini macOS app is available natively for Apple Silicon and macOS 15+.
# Homebrew's google-gemini cask points to the native app.

log "GUI application installation complete"
