# hive project template

A base image and workspace template for developing several GitHub repositories
together inside one sandboxed container that hosts the Pi agent.

## What is here

| Path | Purpose |
|---|---|
| `Dockerfile` | Universal base image (`hive-base`): Ubuntu, Node, Pi, Claude Code, git, west, just. |
| `config/agent/` | Committed Pi and Claude Code configuration. No credentials. |
| `scripts/hive-entrypoint.sh` | Installs mounted harness dependencies on first start. |
| `scripts/doctor.sh` | Health checks, usable on host and in the container. |
| `templates/workspace/` | Files copied into each workspace instance. |
| `docs/BOOTSTRAP.md` | The runbook an agent follows to set up a workspace from a repo list. |

## Concepts

- **Project** (this repo) — the reusable base: image, agent config, template,
  and bootstrap procedure.
- **Workspace** — one instance: a west manifest, the repositories it develops,
  a workspace Dockerfile, compose, justfile, and `AGENTS.md`.

The workspace root is the west topdir. `manifest/west.yml` is tracked by the
workspace repo; west clones each project as a gitignored sibling directory.
`west` and `git` network operations run on the host so credentials never enter
the container.

## Usage

```sh
# Build the base image
just base-build

# Scaffold and initialise a workspace
just new-workspace my-workspace
cd my-workspace
# edit manifest/west.yml, Dockerfile, AGENTS.md, .gitignore
just init
```

See `docs/BOOTSTRAP.md` for the full procedure and `templates/workspace/AGENTS.md`
for the runtime contract.

## Requirements

- A container engine: Docker or Podman (rootless is fine).
- `just`, `west` (`pipx install west`), and `git` on the host.
- Optional: `@devcontainers/cli` for editor integration and lifecycle hooks.
