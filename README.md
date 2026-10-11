# workspaces

Containerised development workspaces for developing several repositories
together with the Pi agent.

## Contents

| Path | What it is |
|---|---|
| `project/` | The reusable **project template**: base image, committed agent config, workspace templates, and the bootstrap runbook. Start here. |
| `example-workspace/` | A scaffolded **workspace instance** used to exercise the template. Replace its manifest with real repositories. |

## Model

- The **project** provides a universal base image (`hive-base`) with Node, Pi,
  Claude Code, git, west, and just, plus a curated `config/agent/` and a
  workspace template.
- A **workspace** is one instance: a west manifest, the repositories it develops
  together, a Dockerfile extending the base image, compose orchestration, a
  justfile, and an `AGENTS.md`.
- `west` and `git` network operations run on the host; the container holds the
  long-running agent and local tooling. Credentials are passed as environment
  variables only.

## Quick start

```sh
cd project
just base-build        # build hive-base:dev
just new-workspace my-workspace
cd ../my-workspace
# edit manifest/west.yml, Dockerfile, AGENTS.md, .gitignore
just init              # preflight, base image, west update, start, doctor
```

See `project/README.md` and `project/docs/BOOTSTRAP.md`.
