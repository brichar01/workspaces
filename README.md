# workspaces

Containerised development workspaces for developing several repositories
together, with agents and other tools added as extensions.

## Contents

| Path | What it is |
|---|---|
| `project/` | The reusable **project template**: base image, example extensions, workspace templates, and the bootstrap runbook. Start here. |
| `example-workspace/` | A scaffolded **workspace instance** used to exercise the template. Replace its manifest with real repositories. |

## Model

- The **project** provides a universal base image (`workspaces_base`) with
  Python, git, west, and just, example extensions in `extensions/` (Pi
  and Claude Code), and a workspace template.
- An **extension** adds a tool, such as an agent, to a workspace. A workspace
  enables extensions in its `.env`.
- A **workspace** is one instance: a west manifest, the repositories it develops
  together, a Dockerfile extending the base image, compose orchestration, a
  justfile, and an `AGENTS.md`.
- `west` and `git` network operations run on the host; the container holds local
  tooling and any enabled extensions. Credentials are passed as environment
  variables only.

## Quick start

```sh
cd project
just base-build        # build workspaces_base:dev
just new-workspace my-workspace
cd ../my-workspace
# edit manifest/west.yml, Dockerfile, AGENTS.md, .gitignore
just init              # check base image, west update, start, doctor
```

See `project/README.md` and `project/docs/BOOTSTRAP.md`.
