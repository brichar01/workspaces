# Workspace: <name>

This workspace develops several repositories together in one container. The
workspace root is a git repository; the repositories themselves are west-managed
subdirectories.

## Quick start (host)

```sh
just init      # preflight, base image, west init + update, start container, doctor
just shell     # shell inside the container
just doctor    # verify the workspace and its extensions
```

From a fresh clone the only prerequisites are `git`, `just`, `west`
(`pipx install west`), a container engine, and credentials for private repos.

## Host vs container boundary

`west` and `git` network operations stay on the host so credentials never enter
the container.

| Task | Where | Command |
|---|---|---|
| Fetch/clone/update all repos | host | `just update` (`west update`) |
| Push changes | host | `git push` inside a project, or `just push` if defined |
| Local git history work | container | `git add/commit/diff/log` |
| Read the manifest | container | `west list`, `west manifest` |
| Run checks/tests | container | `just check`, `just test`, `just doctor` |

## Layout

| Path | Contents | Package manager |
|---|---|---|
| `manifest/west.yml` | west manifest (the source of truth for repos) | — |
| `scripts/engine.sh` | Docker/Podman + devcontainer dispatch | — |
| `compose.yaml` | service, mounts, ports | — |
| `.workspaces/` | staged extensions and generated config (gitignored) | — |
| `.devcontainer/` | editor integration (compose mode) | — |
| `.env` | local secrets/config (gitignored) | — |

Add a row to this table whenever you add a project to `manifest/west.yml`.

## Extensions

Agents and other development tools are extensions, not part of the base image.
Enable them in `.env` with `WORKSPACES_EXTENSIONS="pi claude"`, then run
`just rebuild`. See `extensions/README.md` in the project repo for the format.

| Extension | Purpose |
|---|---|
| — | none enabled |

## Container maintenance

```sh
just ps          # list containers
just logs        # follow container logs
just rebuild     # recreate from scratch (keeps named volumes)
just down        # stop and remove the stack
```

- Base image: `workspaces_base:dev`, built from the project repo by `just base`.
- Workspace image: built from `Dockerfile` (extends the base, installs the
  enabled extensions).
- Docker/Podman differences live only in `scripts/engine.sh`.
- `userns_mode: keep-id` is applied for rootless Podman.

## Troubleshooting

- **`just init` cannot clone a private repo** — run it where your host SSH or
  git credentials work; nothing is forwarded into the container.
- **Files owned by root** — ensure `HOST_UID`/`HOST_GID` match your host ids;
  on Podman use the `compose.podman.yaml` overlay.
- **Extension not found** — the name in `WORKSPACES_EXTENSIONS` must match a
  directory in `WORKSPACES_EXTENSIONS_DIR`.
- **`unsupported index version`** — git on the host is newer than in the image;
  set `git config --global index.version 2` for this workspace.
