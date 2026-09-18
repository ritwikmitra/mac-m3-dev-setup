# mac-dev-setup

A reproducible Apple Silicon macOS developer workstation bootstrap for a backend/platform engineer working with Java/Spring Boot, Go, Python/AI, and Node.js.

## Design principles

- Apple Silicon only (targeted for an M3 Pro/M-series Mac).
- Homebrew for host packages and most GUI applications; casks are used where maintained and applications can self-update.
- `mise` for language/runtime/build-tool versions: Java 25, latest stable Go/Python, latest Node LTS, Maven, Gradle.
- `uv` for Python projects and isolated Python CLI tools.
- No databases installed directly on macOS; Docker Compose templates use `/docker` for persistent data.
- Kubernetes is installed but **not started**; `k8s-up` / `k8s-down` manage a lightweight Colima + k3s profile.
- GUI apps are installed in `/Applications`; many have their own auto-update mechanisms. Safe is installed separately from the Mac App Store because its Homebrew cask is unavailable and its vendor DMG is retired.
- No credentials or SSH keys are copied by the base setup.
- Re-running the setup is intended to be safe. Existing cask artifacts are
  adopted by Homebrew when they match; a conflicting manually installed app
  or command is left untouched and reported as skipped. GUI apps in
  `/Applications` and CLI-only casks are preflighted before Homebrew is asked
  to install them.

## Initial install

Complete macOS first-run setup, then clone/download this repository. A fresh
Mac must use the following order so the Command Line Tools and root-level
synthetic links are ready before the main bootstrap.

### 1. Install Xcode Command Line Tools

Run the Xcode-only helper:

```bash
./scripts/xcode.sh
```

If it launches Apple's interactive installer, complete that installer. The
helper intentionally stops there; do not start the main bootstrap yet. If the
tools are already present, it simply verifies them and exits successfully.

### 2. Configure synthetic developer paths

Refresh administrator authorization, then run the synthetic-path helper:

```bash
sudo -v
./setup.sh --synthetic
```

`sudo -v` prompts for the password of an administrator account (when needed)
and caches that authorization for the privileged operations used by the
scripts. `setup.sh` verifies this cached authorization before doing any work
and stops with this instruction if it is missing. Do not run the entire setup
as root or through `sudo -i`.

### 3. Reboot

Restart the Mac. This is required for macOS to materialize the `/projects` and
`/docker` synthetic symbolic links.

### 4. Run the main bootstrap

After signing back in, refresh sudo authorization again—the previous sudo
credential does not survive a reboot—then run the normal setup. Do not pass
`--synthetic`, because it was already configured in step 2.

```bash
sudo -v
./setup.sh
```

Before installing anything, `setup.sh` also verifies that Xcode Command Line
Tools are available and that the expected `/projects` and `/docker` synthetic
links are active. If either prerequisite is missing, it stops and prints the
required preparation command instead of starting a partial install.

The `./setup.sh --xcode` convenience flag remains available: if it needs to
launch the Xcode installer, it stops so you can complete it; if Xcode is
already installed, it continues with the full bootstrap. For the staged
first-run sequence above, use `./scripts/xcode.sh` so no other setup work can
begin early.

For a hands-off install:

```bash
sudo -v
./setup.sh --non-interactive \
  --git-name="Your Name" \
  --git-email="you@example.com"
```

Optional setup flags/skips:

```bash
./setup.sh --skip-apps
./setup.sh --skip-kubernetes
./setup.sh --skip-ai
./setup.sh --skip-docker
./setup.sh --skip-macos
```

## Installation locations

- Homebrew: `/opt/homebrew`
- mise-managed runtimes: `~/.local/share/mise/installs`
- uv executable: Homebrew prefix; uv tools use uv-managed isolated environments
- GUI applications: `/Applications`
- projects: `/projects` -> `~/projects` via macOS `/etc/synthetic.conf`
- Docker persistent data: `/docker` -> `~/docker` via macOS `/etc/synthetic.conf`
- personal helper scripts: `~/tools/bin`

## Root-level developer paths on modern macOS

Modern macOS keeps the system volume read-only, so ordinary `ln -s` cannot create writable paths directly under `/`. macOS provides `/etc/synthetic.conf` for controlled root-level synthetic symbolic links. The bootstrap therefore keeps the real writable directories under the user's Data volume and can optionally expose them at the root.

Synthetic setup is configured during the staged first-run sequence above. To
add it later on an existing installation, it remains **opt-in**:

```bash
./setup.sh --synthetic
```

The script first checks whether `/projects` and `/docker` already exist. It never replaces an existing physical directory or a conflicting symbolic link. If a path already points to the expected target, it leaves it alone. It also preserves unrelated entries in `/etc/synthetic.conf` and refuses to change a conflicting entry.

The resulting paths are:

```text
/projects -> ~/projects
/docker   -> ~/docker
```

The `synthetic.conf` entries use the required tab-separated format and are materialized during early boot, so a **reboot is required** after adding a new synthetic entry.

The regular filesystem setup runs regardless of whether `--synthetic` is supplied; it creates `~/projects`, `~/docker`, `~/tools/bin`, and `~/scripts`.

## Runtime management

`mise` is installed using its official macOS installer because the mise project recommends the official binary over Homebrew for faster access to new releases.

Global defaults:

- Java 25 (LTS)
- latest stable Go
- latest stable Python
- latest Node LTS
- latest Maven
- latest Gradle

Project-specific versions can be declared later in a repository's `mise.toml`.

## Python

Do not globally install Gradio/Streamlit. Keep them in project environments:

```bash
cd /projects/experiments/my-app
uv init
uv add gradio streamlit
uv run python app.py
```

`ruff` is installed as an isolated global uv tool for general Python formatting/linting.

## Local Docker infrastructure

Persistent data lives under:

```text
/docker/
├── db/
│   ├── postgres/
│   ├── mysql/
│   ├── redis/
│   ├── mongodb/
│   └── cassandra/
├── messaging/kafka/
├── search/{elasticsearch,opensearch}/
├── analytics/clickhouse/
├── vector/qdrant/
└── automation/n8n/
```

Compose definitions live under `/projects/experiments/local-infrastructure`.

Examples:

```bash
docker-local-up postgres
docker-local-down postgres

docker-local-up redis
docker-local-up qdrant
docker-local-up n8n
docker-local-down n8n
```

Or generate a standalone template:

```bash
docker-template postgres
docker-template kafka
docker-template qdrant
docker-template n8n
```

Nothing is started automatically.

## Kubernetes

Installed:

- Colima
- k3s through Colima
- kubectl
- Helm
- k9s

Start only when required:

```bash
k8s-up
```

Stop it when finished:

```bash
k8s-down
```

The default profile is 4 CPU / 6 GB RAM / 40 GB disk. Adjust `scripts/kubernetes.sh` if a workload needs more.

## Updating

Use:

```bash
mac-update
```

This updates Homebrew formulas/casks, mise, mise-managed tools, Gemini CLI, and Hugging Face CLI. GUI applications that self-update can also update themselves independently.

## Authentication

The bootstrap deliberately does not automate:

- GitHub login
- SSH key restoration
- Claude/Gemini/Codex authentication
- Hugging Face login
- Docker registry credentials
- Postman login
- SafeInCloud vault restoration

These should be performed interactively after installation.

## Important security note

`mise` configuration files can contain environment directives and executable tasks. Treat project `mise.toml` files as code and only trust repositories you intend to run.
