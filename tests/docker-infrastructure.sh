#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

mkdir -p "$TEST_ROOT/home/tools/bin" "$TEST_ROOT/bin"
cat > "$TEST_ROOT/bin/brew" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$TEST_ROOT/bin/brew"

HOME="$TEST_ROOT/home" PATH="$TEST_ROOT/bin:$PATH" bash "$ROOT_DIR/scripts/docker.sh"

[[ -d "$TEST_ROOT/home/docker/automation/n8n" ]] || {
  echo "n8n persistent-data directory was not created" >&2
  exit 1
}

STACK="$TEST_ROOT/home/projects/experiments/local-infrastructure/docker-compose.yml"
TEMPLATE="$TEST_ROOT/home/docker/compose/automation/n8n.yml"

ruby -ryaml -e '
  stack = YAML.safe_load(File.read(ARGV.fetch(0)), aliases: true)
  n8n = stack.fetch("services").fetch("n8n")
  abort "wrong n8n image" unless n8n.fetch("image") == "docker.n8n.io/n8nio/n8n:latest"
  abort "wrong n8n profile" unless n8n.fetch("profiles") == ["n8n"]
  abort "wrong n8n port" unless n8n.fetch("ports") == ["5678:5678"]
  abort "wrong n8n volume" unless n8n.fetch("volumes") == ["/docker/automation/n8n:/home/node/.n8n"]
' "$STACK"

ruby -ryaml -e '
  template = YAML.safe_load(File.read(ARGV.fetch(0)), aliases: true)
  n8n = template.fetch("services").fetch("n8n")
  abort "wrong template image" unless n8n.fetch("image") == "docker.n8n.io/n8nio/n8n:latest"
  abort "wrong template port" unless n8n.fetch("ports") == ["5678:5678"]
  abort "wrong template volume" unless n8n.fetch("volumes") == ["/docker/automation/n8n:/home/node/.n8n"]
' "$TEMPLATE"

echo "Docker infrastructure checks passed"
