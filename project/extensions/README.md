# Extensions

An extension adds a development tool, such as an agent, to a workspace without
changing the base image or the workspace template. Pi and Claude Code are
supplied here as examples.

## Enable an extension

In the workspace `.env`, list the extensions by directory name:

```sh
WORKSPACES_EXTENSIONS="pi claude"
```

Set `WORKSPACES_EXTENSIONS_DIR` to the absolute path of this directory, or of
any directory of extensions, then run `just rebuild`. `scripts/engine.sh` copies
each listed extension into the workspace's gitignored `.workspaces/extensions/`
directory. The workspace image installs
everything there. Credentials go in `.env`, never in an extension.

## Layout

Every file is optional.

| File | Runs | Purpose |
|---|---|---|
| `install.sh` | image build, as root | Install the tool. Gets `EXTENSION_DIR` and `WORKSPACES_USER`. |
| `entrypoint.d/*.sh` | container start, as the workspace user | Prepare state, for example install dependencies in a mounted checkout. A failure stops the container. |
| `compose.yaml` | `just up`, `just rebuild` | Compose fragment merged over the workspace service `workspaces_dev`: command, ports, volumes, healthcheck. |
| `doctor.d/*.sh` | `just doctor` | Checks, sourced by `workspaces_doctor`. Use `ok`, `bad`, `warnf` and `have`. |

The extension directory is copied to `/opt/extensions/<name>/` in the image, so
`install.sh` can link config files from `${EXTENSION_DIR}`.

An extension runs as root at build time. Only enable extensions you trust.

## Add your own

Put the directory anywhere, then point `WORKSPACES_EXTENSIONS_DIR` at its
parent, or copy it into this directory. One workspace reads from one
extensions directory. A tool's own repository is a good home
for its extension.
