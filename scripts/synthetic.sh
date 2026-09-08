#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/common.sh"

SYNTHETIC_CONF="/etc/synthetic.conf"

# synthetic.conf uses a tab-separated name and relative target. macOS reads it
# during early boot because the system volume is read-only.
ensure_synthetic_link() {
  local name="$1"
  local target="$2"
  local root_path="/$name"
  local existing_conf=""
  local resolved=""

  if [[ -e "$root_path" || -L "$root_path" ]]; then
    if [[ ! -L "$root_path" ]]; then
      die "$root_path already exists and is not a symbolic link. Refusing to replace it."
    fi
    resolved="$(readlink "$root_path")"
    if [[ "$resolved" != "$target" && "/$resolved" != "/$target" ]]; then
      die "$root_path already exists and points to $resolved; expected $target. Refusing to change it."
    fi
    log "$root_path already exists and points to $resolved; leaving it unchanged."
  fi

  if [[ -f "$SYNTHETIC_CONF" ]]; then
    existing_conf="$(sudo awk -v name="$name" '$1 == name { print $2; exit }' "$SYNTHETIC_CONF")"
  fi

  if [[ -n "$existing_conf" ]]; then
    [[ "$existing_conf" == "$target" ]] || die "/$name is already configured in $SYNTHETIC_CONF as $existing_conf; refusing to change it."
    log "/$name is already correctly configured in $SYNTHETIC_CONF."
    return 0
  fi

  log "Adding /$name -> /$target to $SYNTHETIC_CONF"
  local tmp
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' RETURN

  if [[ -f "$SYNTHETIC_CONF" ]]; then
    sudo cat "$SYNTHETIC_CONF" > "$tmp"
  fi
  printf '%s\t%s\n' "$name" "$target" >> "$tmp"
  sudo install -o root -g wheel -m 0644 "$tmp" "$SYNTHETIC_CONF"
  rm -f "$tmp"
  trap - RETURN
}

log "Configuring synthetic root-level developer paths"

# Real writable directories always live in the user's Data volume.
mkdir -p "$HOME/projects/personal" "$HOME/projects/work" "$HOME/projects/experiments"
mkdir -p "$HOME/docker"

USER_NAME="$(id -un)"
ensure_synthetic_link "projects" "Users/$USER_NAME/projects"
ensure_synthetic_link "docker" "Users/$USER_NAME/docker"

warn "A reboot is required before newly-added synthetic paths appear at /projects and /docker."
