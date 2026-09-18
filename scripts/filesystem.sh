#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/common.sh"

log "Creating developer filesystem"
mkdir -p \
  "$HOME/projects/personal" \
  "$HOME/projects/work" \
  "$HOME/projects/experiments"
mkdir -p "$HOME/tools/bin" "$HOME/scripts"

# Docker data/configuration lives here. The optional synthetic setup exposes it
# as /docker without requiring sudo for normal use.
mkdir -p \
  "$HOME/docker/db/postgres" \
  "$HOME/docker/db/mysql" \
  "$HOME/docker/db/redis" \
  "$HOME/docker/db/mongodb" \
  "$HOME/docker/db/cassandra" \
  "$HOME/docker/messaging/kafka" \
  "$HOME/docker/search/elasticsearch" \
  "$HOME/docker/search/opensearch" \
  "$HOME/docker/analytics/clickhouse" \
  "$HOME/docker/vector/qdrant" \
  "$HOME/docker/automation/n8n" \
  "$HOME/docker/compose"

cp -n "$ROOT_DIR/docker/templates/README.md" "$HOME/docker/README.md" 2>/dev/null || true
