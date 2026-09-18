#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/common.sh"

log "Installing Docker Desktop"
if [[ ! -d "/Applications/Docker.app" ]]; then
  brew install --cask docker-desktop
fi

mkdir -p "$HOME/docker/db" "$HOME/docker/messaging" "$HOME/docker/search" "$HOME/docker/analytics" "$HOME/docker/vector" "$HOME/docker/automation/n8n" "$HOME/docker/compose"

cat > "$HOME/docker/README.md" <<'README'
# Local Docker data

Persistent local development data lives here. Compose definitions normally live under `/projects/experiments`.

- `db/` - PostgreSQL, MySQL, Redis, MongoDB, Cassandra
- `messaging/` - Kafka
- `search/` - Elasticsearch, OpenSearch
- `analytics/` - ClickHouse
- `vector/` - Qdrant
- `automation/` - n8n
- `compose/` - shared Compose assets

Nothing in this directory is started automatically by the bootstrap.
README

# Copy standalone templates for easy reuse.
cp -R "$ROOT_DIR/docker/templates/." "$HOME/docker/compose/"

# Create one opt-in stack with Compose profiles.
mkdir -p "$HOME/projects/experiments/local-infrastructure"
cat > "$HOME/projects/experiments/local-infrastructure/docker-compose.yml" <<'COMPOSE'
services:
  postgres:
    image: postgres:latest
    profiles: [postgres]
    environment: { POSTGRES_USER: dev, POSTGRES_PASSWORD: dev, POSTGRES_DB: dev }
    ports: ["5432:5432"]
    volumes: ["/docker/db/postgres:/var/lib/postgresql/data"]

  mysql:
    image: mysql:latest
    profiles: [mysql]
    environment: { MYSQL_ROOT_PASSWORD: root, MYSQL_USER: dev, MYSQL_PASSWORD: dev, MYSQL_DATABASE: dev }
    ports: ["3306:3306"]
    volumes: ["/docker/db/mysql:/var/lib/mysql"]

  redis:
    image: redis:latest
    profiles: [redis]
    command: ["redis-server", "--appendonly", "yes"]
    ports: ["6379:6379"]
    volumes: ["/docker/db/redis:/data"]

  mongodb:
    image: mongo:latest
    profiles: [mongodb]
    environment: { MONGO_INITDB_ROOT_USERNAME: dev, MONGO_INITDB_ROOT_PASSWORD: dev }
    ports: ["27017:27017"]
    volumes: ["/docker/db/mongodb:/data/db"]

  cassandra:
    image: cassandra:latest
    profiles: [cassandra]
    ports: ["9042:9042"]
    volumes: ["/docker/db/cassandra:/var/lib/cassandra"]

  kafka:
    image: apache/kafka:latest
    profiles: [kafka]
    ports: ["9092:9092"]
    environment:
      KAFKA_NODE_ID: 1
      KAFKA_PROCESS_ROLES: broker,controller
      KAFKA_LISTENERS: PLAINTEXT://:9092,CONTROLLER://:9093
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
      KAFKA_CONTROLLER_QUORUM_VOTERS: 1@kafka:9093
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
    volumes: ["/docker/messaging/kafka:/var/lib/kafka/data"]

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:latest
    profiles: [elasticsearch]
    environment: { discovery.type: single-node, xpack.security.enabled: "false", ES_JAVA_OPTS: "-Xms1g -Xmx1g" }
    ports: ["9200:9200"]
    volumes: ["/docker/search/elasticsearch:/usr/share/elasticsearch/data"]

  opensearch:
    image: opensearchproject/opensearch:latest
    profiles: [opensearch]
    environment: { discovery.type: single-node, DISABLE_SECURITY_PLUGIN: "true", OPENSEARCH_JAVA_OPTS: "-Xms1g -Xmx1g" }
    ports: ["9201:9200"]
    volumes: ["/docker/search/opensearch:/usr/share/opensearch/data"]

  clickhouse:
    image: clickhouse/clickhouse-server:latest
    profiles: [clickhouse]
    ports: ["8123:8123", "9000:9000"]
    volumes: ["/docker/analytics/clickhouse:/var/lib/clickhouse"]

  qdrant:
    image: qdrant/qdrant:latest
    profiles: [qdrant]
    ports: ["6333:6333", "6334:6334"]
    volumes: ["/docker/vector/qdrant:/qdrant/storage"]

  n8n:
    image: docker.n8n.io/n8nio/n8n:latest
    profiles: [n8n]
    ports: ["5678:5678"]
    volumes: ["/docker/automation/n8n:/home/node/.n8n"]
COMPOSE

cat > "$HOME/tools/bin/docker-local-up" <<'CMD'
#!/usr/bin/env bash
set -Eeuo pipefail
service="${1:?Usage: docker-local-up <postgres|mysql|redis|mongodb|cassandra|kafka|elasticsearch|opensearch|clickhouse|qdrant|n8n>}"
cd /projects/experiments/local-infrastructure
docker compose --profile "$service" up -d "$service"
CMD
cat > "$HOME/tools/bin/docker-local-down" <<'CMD'
#!/usr/bin/env bash
set -Eeuo pipefail
service="${1:?Usage: docker-local-down <service>}"
cd /projects/experiments/local-infrastructure
docker compose --profile "$service" stop "$service"
CMD
cat > "$HOME/tools/bin/docker-local-rm" <<'CMD'
#!/usr/bin/env bash
set -Eeuo pipefail
service="${1:?Usage: docker-local-rm <service>}"
cd /projects/experiments/local-infrastructure
docker compose --profile "$service" rm -f "$service"
CMD
chmod +x "$HOME/tools/bin/docker-local-up" "$HOME/tools/bin/docker-local-down" "$HOME/tools/bin/docker-local-rm"
