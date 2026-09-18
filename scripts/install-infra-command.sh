#!/usr/bin/env bash
set -Eeuo pipefail
mkdir -p "$HOME/tools/bin"
cat > "$HOME/tools/bin/docker-template" <<'CMD'
#!/usr/bin/env bash
set -Eeuo pipefail
name="${1:?Usage: docker-template <postgres|mysql|redis|mongodb|cassandra|kafka|elasticsearch|opensearch|clickhouse|qdrant|n8n>}"
base="/docker/compose"
dest="/projects/experiments/local-infrastructure/${name}.yml"
case "$name" in
  postgres|mysql|redis|mongodb|cassandra) src="$base/db/$name.yml" ;;
  kafka) src="$base/messaging/kafka.yml" ;;
  elasticsearch|opensearch) src="$base/search/$name.yml" ;;
  clickhouse) src="$base/analytics/clickhouse.yml" ;;
  qdrant) src="$base/vector/qdrant.yml" ;;
  n8n) src="$base/automation/n8n.yml" ;;
  *) echo "Unknown template: $name" >&2; exit 1 ;;
esac
mkdir -p /projects/experiments/local-infrastructure
cp "$src" "$dest"
echo "Created $dest"
CMD
chmod +x "$HOME/tools/bin/docker-template"
