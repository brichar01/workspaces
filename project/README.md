# workspaces project template

A base image and workspace template for developing several repositories
together inside one sandboxed container. Agents and other development tools are
added as extensions.

## What is here

| Path | Purpose |
|---|---|
| `Dockerfile` | Universal base image (`workspaces_base`): Ubuntu, Python, git, west, just. No agents and no Node. |
| `extensions/` | Example extensions, `pi` and `claude`, and the extension format. |
| `scripts/entrypoint.sh` | Runs each installed extension's start hooks. |
| `scripts/install-extensions.sh` | Runs each staged extension's `install.sh` at image build. |
| `scripts/doctor.sh` | Health checks, usable on host and in the container. Runs extension checks. |
| `templates/workspace/` | Files copied into each workspace instance. |
| `docs/BOOTSTRAP.md` | The runbook an agent follows to set up a workspace from a repo list. |

## Concepts

- **Project** (this repo): the reusable base. Image, example extensions,
  template and bootstrap procedure.
- **Workspace**: one instance. A west manifest, the repositories it develops,
  a workspace Dockerfile, compose, justfile, and `AGENTS.md`.
- **Extension**: a directory that adds a tool to a workspace at build, start,
  compose and doctor time. A workspace enables extensions in its `.env`. See
  `extensions/README.md`.

The workspace root is the west topdir. `manifest/west.yml` is tracked by the
workspace repo. west clones each project as a gitignored subdirectory.
`west` and `git` network operations run on the host so credentials never enter
the container.

## Usage

```sh
# Build the base image
just base-build

# Scaffold and initialise a workspace
just new-workspace my-workspace
cd ../my-workspace
# edit manifest/west.yml, Dockerfile, AGENTS.md, .gitignore, .env
just init
```

See `docs/BOOTSTRAP.md` for the full procedure and `templates/workspace/AGENTS.md`
for the runtime contract.

## Requirements

- A container engine: Docker or Podman (rootless is fine).
- `just`, `west` (`pipx install west`), `git` and `python3` on the host.
- Optional: `@devcontainers/cli` for editor integration and lifecycle hooks.
