#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/common.sh"

log "Configuring Zsh + Oh My Zsh + Starship"

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

ZSHRC="$HOME/.zshrc"
touch "$ZSHRC"
START="# >>> mac-dev-setup >>>"
END="# <<< mac-dev-setup <<<"

if ! command -v starship >/dev/null 2>&1; then brew install starship; fi

if ! grep -qF "$START" "$ZSHRC"; then
  cat >> "$ZSHRC" <<'ZSH'

# >>> mac-dev-setup >>>
export PATH="$HOME/.local/bin:$HOME/tools/bin:/opt/homebrew/bin:$PATH"

# Project/runtime environment management.
eval "$(mise activate zsh)"
eval "$(direnv hook zsh)"

# Modern prompt.
eval "$(starship init zsh)"

# fzf shell integration.
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh) 2>/dev/null || true
fi

# Stable Git aliases used by this workstation.
alias gst='git status'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gaa='git add --all'
alias gcmsg='git commit -m'
alias gp='git push'
alias gl='git pull'
alias glog='git log --oneline --decorate --graph --all'

# Navigation shortcuts.
alias ll='ls -lah'
alias ..='cd ..'
alias proj='cd /projects'
alias personal='cd /projects/personal'
alias work='cd /projects/work'
alias experiments='cd /projects/experiments'
alias docker-root='cd /docker'

# Lightweight Kubernetes lifecycle.
k8s-up() { "$HOME/tools/bin/k8s-up"; }
k8s-down() { "$HOME/tools/bin/k8s-down"; }

# Local Docker service helpers.
docker-local-up() { "$HOME/tools/bin/docker-local-up" "$@"; }
docker-local-down() { "$HOME/tools/bin/docker-local-down" "$@"; }
docker-local-rm() { "$HOME/tools/bin/docker-local-rm" "$@"; }

# <<< mac-dev-setup <<<
ZSH
fi

# Let Oh My Zsh's built-in plugin files be sourced explicitly without changing
# the user's existing plugin declaration semantics.
for plugin in docker kubectl helm mise; do
  plugin_file="$HOME/.oh-my-zsh/plugins/$plugin/$plugin.plugin.zsh"
  if [[ -f "$plugin_file" ]] && ! grep -qF "source \"$plugin_file\"" "$ZSHRC"; then
    printf '\nsource "%s"\n' "$plugin_file" >> "$ZSHRC"
  fi
done

mise completion zsh --install >/dev/null 2>&1 || true
