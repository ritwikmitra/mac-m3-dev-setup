# Local infrastructure templates

These are intentionally **not started by the Mac bootstrap**.

Copy or adapt a template into `/projects/experiments/local-infrastructure` and start it only when needed.

Persistent state is stored under `/docker` so deleting a project/Compose definition does not delete database data.

Suggested defaults:
- PostgreSQL: localhost:5432 / dev / dev / dev
- MySQL: localhost:3306 / dev / dev
- Redis: localhost:6379
- MongoDB: localhost:27017 / dev / dev
- Cassandra: localhost:9042
- Kafka: localhost:9092
- Elasticsearch: localhost:9200
- OpenSearch: localhost:9201
- ClickHouse HTTP: localhost:8123
- Qdrant: localhost:6333

Images use `latest` intentionally for a development template. Pin an image tag in a real project when reproducibility matters.
