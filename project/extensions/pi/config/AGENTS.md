# Shared agent instructions (Pi)

These instructions apply to every workspace that uses this image. Workspace and
repository `AGENTS.md` files add project-specific detail on top of them.

## Environment

- You are running inside a container. The workspace is mounted at `/workspace`.
- `just` is the entrypoint for routine work. Prefer `just <recipe>` over ad hoc
  shell pipelines, and add a recipe when one is missing.

## Boundaries

- `west` and `git` may be used for local, read-only, or history operations
  (`status`, `diff`, `log`, `add`, `commit`, `west list`, `west manifest`).
- Network git operations (fetch, pull, push, private `west update`) belong to
  the **host**. Do not attempt them from inside the container; ask the human to
  run `just update` / `just push`.
- Never read, print, or exfiltrate credentials. API keys arrive as environment
  variables and must not be written to files or committed.

## Style

- Read a file before editing it. Keep diffs small and purposeful.
- After changing code, run the relevant `just check` / `just test` recipe.
- Update `AGENTS.md` when you discover a command, dependency, or gotcha that
  another agent would need.
