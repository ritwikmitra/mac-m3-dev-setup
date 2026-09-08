#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT_DIR/scripts/common.sh"

NON_INTERACTIVE=false
GIT_NAME=""
GIT_EMAIL=""
SKIP_APPS=false
SKIP_MACOS=false
SKIP_DOCKER=false
SKIP_K8S=false
SKIP_AI=false
INSTALL_XCODE=false
CONFIGURE_SYNTHETIC=false

usage() {
  cat <<USAGE
Usage: ./setup.sh [options]

Options:
  --non-interactive          Run without prompts (recommended for automation)
  --git-name=NAME            Configure global Git user.name
  --git-email=EMAIL          Configure global Git user.email
  --skip-apps                Skip GUI applications
  --skip-macos               Skip macOS preference configuration
  --skip-docker              Skip Docker Desktop and Docker layout
  --skip-kubernetes          Skip Kubernetes CLI/runtime setup
  --skip-ai                  Skip AI tools/apps
  --xcode                    Install/check Xcode Command Line Tools, then continue when available
  --synthetic                Configure synthetic paths, then stop for the required reboot
  -h, --help                 Show this help

Examples:
  ./setup.sh
  ./setup.sh --non-interactive --git-name="Your Name" --git-email="you@example.com"
  ./setup.sh --skip-kubernetes
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --non-interactive) NON_INTERACTIVE=true ;;
    --git-name=*) GIT_NAME="${arg#*=}" ;;
    --git-email=*) GIT_EMAIL="${arg#*=}" ;;
    --skip-apps) SKIP_APPS=true ;;
    --skip-macos) SKIP_MACOS=true ;;
    --skip-docker) SKIP_DOCKER=true ;;
    --skip-kubernetes) SKIP_K8S=true ;;
    --skip-ai) SKIP_AI=true ;;
    --xcode) INSTALL_XCODE=true ;;
    --synthetic) CONFIGURE_SYNTHETIC=true ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $arg" ;;
  esac
done

require_apple_silicon
require_cached_sudo_authorization

log "Starting Mac developer workstation setup"

if [[ "$INSTALL_XCODE" == true ]]; then
  "$ROOT_DIR/scripts/xcode.sh" || exit $?
fi

"$ROOT_DIR/scripts/prerequisites.sh"
if [[ "$CONFIGURE_SYNTHETIC" == true ]]; then
  "$ROOT_DIR/scripts/synthetic.sh"
  warn "Synthetic paths are configured. Reboot now, then run 'sudo -v' and './setup.sh' without --synthetic."
  exit 0
fi

require_active_synthetic_links
"$ROOT_DIR/scripts/homebrew.sh"
"$ROOT_DIR/scripts/filesystem.sh"
"$ROOT_DIR/scripts/runtimes.sh"
"$ROOT_DIR/scripts/developer-tools.sh" "$GIT_NAME" "$GIT_EMAIL"
"$ROOT_DIR/scripts/shell.sh" "$NON_INTERACTIVE"
"$ROOT_DIR/scripts/install-update-command.sh"
"$ROOT_DIR/scripts/install-infra-command.sh"

if [[ "$SKIP_DOCKER" != true ]]; then
  "$ROOT_DIR/scripts/docker.sh"
fi

if [[ "$SKIP_K8S" != true ]]; then
  "$ROOT_DIR/scripts/kubernetes.sh"
fi

if [[ "$SKIP_APPS" != true ]]; then
  "$ROOT_DIR/scripts/applications.sh" "$SKIP_AI"
fi

if [[ "$SKIP_MACOS" != true ]]; then
  "$ROOT_DIR/scripts/macos.sh"
fi

if [[ -n "$GIT_NAME" ]]; then git config --global user.name "$GIT_NAME"; fi
if [[ -n "$GIT_EMAIL" ]]; then git config --global user.email "$GIT_EMAIL"; fi

cat <<'DONE'

============================================================
 Setup complete
============================================================

Open a new Warp/Terminal window, then verify:

  mise doctor
  java -version
  go version
  python --version
  node --version
  npm --version
  mvn --version
  gradle --version
  docker version
  kubectl version --client
  claude --version
  codex --version
  hf --help

Useful commands:
  mac-update       Update Brew + mise-managed runtimes/tools
  k8s-up           Start lightweight local Kubernetes
  k8s-down         Stop lightweight local Kubernetes
  docker-local-up postgres   Start a selected local service

If you used --synthetic, reboot once before using /projects or /docker.
Those root-level paths are created by macOS from /etc/synthetic.conf.

Authentication for GitHub, AI tools, Postman, etc. is intentionally
left interactive and is not automated by the base installer.
DONE
