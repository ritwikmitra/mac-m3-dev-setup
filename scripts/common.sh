#!/usr/bin/env bash
set -Eeuo pipefail

export PATH="$HOME/.local/bin:/opt/homebrew/bin:$HOME/tools/bin:$PATH"

log() { printf '\n\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\n\033[1;33mWARNING:\033[0m %s\n' "$*" >&2; }
die() { printf '\n\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

is_installed() { command -v "$1" >/dev/null 2>&1; }

require_apple_silicon() {
  [[ "$(uname -s)" == "Darwin" ]] || die "This bootstrap targets macOS."
  [[ "$(uname -m)" == "arm64" ]] || die "This bootstrap targets Apple Silicon (arm64)."
}

require_cached_sudo_authorization() {
  [[ "$EUID" -ne 0 ]] || die "Run setup as your normal macOS user, not root."
  sudo -n -v >/dev/null 2>&1 || die "Administrator authorization is required. Run 'sudo -v' first, then rerun ./setup.sh."
}

require_active_synthetic_links() {
  local user_name expected_projects expected_docker
  user_name="$(id -un)"
  expected_projects="Users/$user_name/projects"
  expected_docker="Users/$user_name/docker"

  [[ -L /projects && "$(readlink /projects)" == "$expected_projects" ]] || \
    die "The /projects synthetic link is not active. Run 'sudo -v', then './setup.sh --synthetic', reboot, and rerun ./setup.sh."
  [[ -L /docker && "$(readlink /docker)" == "$expected_docker" ]] || \
    die "The /docker synthetic link is not active. Run 'sudo -v', then './setup.sh --synthetic', reboot, and rerun ./setup.sh."
}

brew_install_formulae() {
  local packages=("$@")
  [[ ${#packages[@]} -gt 0 ]] || return 0
  brew install "${packages[@]}"
}

brew_install_casks() {
  local packages=("$@")
  local package output
  [[ ${#packages[@]} -gt 0 ]] || return 0

  # Install one cask at a time so a manually installed application does not
  # prevent the remaining workstation applications from being configured.
  # --adopt lets Homebrew manage an identical existing artifact.  If the
  # artifact differs, preserve it rather than overwriting a user's app.
  for package in "${packages[@]}"; do
    if brew list --cask "$package" >/dev/null 2>&1; then
      log "Cask $package is already installed"
      continue
    fi

    if output="$(brew install --cask --adopt "$package" 2>&1)"; then
      [[ -z "$output" ]] || printf '%s\n' "$output"
      continue
    fi

    printf '%s\n' "$output" >&2
    if [[ "$output" == *"It seems there is already an "* || "$output" == *"It seems there is already a "* ]]; then
      warn "Cask $package conflicts with an existing artifact; leaving it unchanged."
      continue
    fi

    return 1
  done
}

ask_yes_no() {
  local prompt="$1"
  local default="${2:-Y}"
  if [[ "${NON_INTERACTIVE:-false}" == true ]]; then
    [[ "$default" == Y ]]
    return
  fi
  local answer
  read -r -p "$prompt [y/N] " answer
  [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]
}
