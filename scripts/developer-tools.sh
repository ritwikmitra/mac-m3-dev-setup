#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/common.sh"
GIT_NAME="${1:-}"
GIT_EMAIL="${2:-}"

log "Installing developer CLI tools"
brew_install_formulae \
  git gh lazygit jq yq ripgrep fd fzf tree httpie wget watch btop \
  direnv pre-commit shellcheck gitleaks trivy mkcert uv golangci-lint \
  kubectl helm k9s

# Hugging Face now provides a standalone hf CLI; prefer it over a global Python env.
if ! command -v hf >/dev/null 2>&1; then
  curl -LsSf https://hf.co/cli/install.sh | bash
fi

# Ensure mise is available for CLI tools after shell setup.
export PATH="$HOME/.local/bin:$PATH"

# Claude Code is distributed as a maintained Homebrew cask on macOS.
# It installs the `claude` CLI without requiring a global npm package.
if ! command -v claude >/dev/null 2>&1; then
  brew install --cask claude-code
fi

# Gemini CLI: use the official npm package and stable/latest channel.
if ! command -v gemini >/dev/null 2>&1; then
  mise exec -- npm install -g @google/gemini-cli@latest
fi

# Codex CLI is installed as a Homebrew cask by applications.sh.

# Install a small set of globally useful Python developer CLIs in isolated uv tool environments.
if command -v uv >/dev/null 2>&1; then
  uv tool install ruff --force >/dev/null 2>&1 || true
fi

# Git configuration is only set when explicitly supplied.
if [[ -n "$GIT_NAME" ]]; then git config --global user.name "$GIT_NAME"; fi
if [[ -n "$GIT_EMAIL" ]]; then git config --global user.email "$GIT_EMAIL"; fi

# Global ignores for local machine metadata.
git config --global core.excludesFile "$HOME/.gitignore_global"
touch "$HOME/.gitignore_global"
grep -qxF '.DS_Store' "$HOME/.gitignore_global" || echo '.DS_Store' >> "$HOME/.gitignore_global"
grep -qxF '.idea/' "$HOME/.gitignore_global" || echo '.idea/' >> "$HOME/.gitignore_global"
grep -qxF '.vscode/' "$HOME/.gitignore_global" || echo '.vscode/' >> "$HOME/.gitignore_global"
