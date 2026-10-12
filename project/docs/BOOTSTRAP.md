# Bootstrap runbook

Follow these steps when asked to build a workspace from a list of repositories
and other details. Stop and report if a repository is unreachable or a
dependency has no obvious package manager.

## 0. Inputs

Collect: workspace name, the list of repositories (URL + revision), the
extensions to enable, any per-repo build/test commands, and any hardware or env
requirements.

## 1. Scaffold

```sh
cd <project>
just base-build
just new-workspace <name>
cd ../<name>
```

`new-workspace` sets `COMPOSE_PROJECT_NAME` and `WORKSPACE_IMAGE` in
`.env.example` to the workspace name. Compose refuses to start if either is
empty, so two workspaces never share a stack, image or volumes.

## 2. Fill in the manifest

Edit `manifest/west.yml` and add one entry per repository:

```yaml
  projects:
    - name: <dir-name>
      url: <clone-url>
      revision: <branch-or-sha>
      path: <dir-name>
```

Use the SSH URL for private repositories; cloning happens on the host. Set
`submodules: true` on any repository with a `.gitmodules` file.

List only the repositories under development. Do **not** add `hive.nvim` or any
other development tool to the manifest. Tools reach the container as
extensions (step 5).

## 3. Record the dependency map

For each project, add a row to the table in `AGENTS.md`:

| Path | Contents | Package manager |
|---|---|---|
| `<dir>` | <what it is> | <npm/cargo/pip/...> |

Then add the matching toolchain to `Dockerfile` under `per-repo extras`.

## 4. Ignore the checkouts

Add each project path to `.gitignore` so `west update` output is never committed.

## 5. Enable extensions

Agents and other development tools are extensions. The project supplies `pi`
and `claude` in `extensions/`. To enable them, uncomment and set in `.env`:

```sh
WORKSPACES_EXTENSIONS="pi claude"
```

Add the credentials they need to `.env`, and list each one in the Extensions
table in `AGENTS.md`. Leave them commented out in `.env.example` and other
tracked files so each developer opts in. See `extensions/README.md` to write a
new one.

## 6. Initialise and verify

```sh
just init     # preflight, base image, west init + update, start, doctor
just doctor   # must end with "0 failures"
```

## 7. Wire up checks

Replace the placeholder `_check` and `_test` recipes in the workspace `justfile`
with real per-repo commands, then confirm `just check` and `just test` pass.

## 8. Commit

Commit the workspace (manifest, Dockerfile, compose, justfile, AGENTS.md,
.gitignore). Do **not** commit `.env` or any project checkout.

## Checklist

- [ ] `manifest/west.yml` validates (`west manifest --validate`).
- [ ] `just init` finishes and `just doctor` reports 0 failures.
- [ ] `.gitignore` covers every project path.
- [ ] `AGENTS.md` dependency table matches the manifest and Dockerfile.
- [ ] No development tool (`hive.nvim`, agents) is in the manifest.
- [ ] `just check` and `just test` run the repositories' real checks.
- [ ] No credentials in the image, the workspace, or git history.
