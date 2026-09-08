#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/common.sh"

log "Installing lightweight Kubernetes runtime (Colima + k3s)"
brew_install_formulae colima

# Create the lifecycle helpers as real commands in ~/tools/bin.
cat > "$HOME/tools/bin/k8s-up" <<'CMD'
#!/usr/bin/env bash
set -Eeuo pipefail
if colima status k8s >/dev/null 2>&1; then
  colima start k8s --kubernetes --cpu 4 --memory 6 --disk 40
else
  colima start k8s --kubernetes --cpu 4 --memory 6 --disk 40
fi
CMD
cat > "$HOME/tools/bin/k8s-down" <<'CMD'
#!/usr/bin/env bash
set -Eeuo pipefail
colima stop k8s
CMD
chmod +x "$HOME/tools/bin/k8s-up" "$HOME/tools/bin/k8s-down"

# Do not start the VM/cluster during bootstrap.
