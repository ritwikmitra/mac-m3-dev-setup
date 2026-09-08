#!/usr/bin/env bash
set -Eeuo pipefail
mkdir -p "$HOME/tools/bin"
cat > "$HOME/tools/bin/mac-update" <<'UPDATE'
#!/usr/bin/env bash
set -Eeuo pipefail

printf '\n==> Updating Homebrew\n'
brew update
brew upgrade
brew upgrade --cask --greedy || true
brew cleanup

printf '\n==> Updating mise and managed development tools\n'
export PATH="$HOME/.local/bin:$PATH"
if command -v mise >/dev/null 2>&1; then
  mise self-update || true
  mise upgrade || true
fi

printf '\n==> Updating Gemini CLI\n'
if command -v npm >/dev/null 2>&1; then
  npm install -g @google/gemini-cli@latest
fi

printf '\n==> Updating Hugging Face CLI\n'
command -v hf >/dev/null 2>&1 && hf update || true

printf '\n==> Versions\n'
mise --version 2>/dev/null || true
java -version 2>&1 | head -1 || true
go version 2>/dev/null || true
python --version 2>/dev/null || true
node --version 2>/dev/null || true
claude --version 2>/dev/null || true
codex --version 2>/dev/null || true
gemini --version 2>/dev/null || true
hf --version 2>/dev/null || true

printf '\nUpdate complete.\n'
UPDATE
chmod +x "$HOME/tools/bin/mac-update"
