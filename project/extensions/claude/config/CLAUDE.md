# Shared agent instructions (Claude Code)

These instructions apply to every workspace that uses this image. Workspace and
repository `CLAUDE.md` / `AGENTS.md` files add project-specific detail.

## Environment

- You are running inside a container. The workspace is mounted at `/workspace`.
- Prefer `just <recipe>` for routine work.

## Boundaries

- `git` and `west` are for local, read-only, or history operations only.
- Network git operations (fetch, pull, push, private `west update`) run on the
  **host**, not here. Ask the human to run `just update` / `just push`.
- Never read, print, or write credentials. API keys arrive via environment
  variables.

## Style

- Read before editing; keep diffs small.
- Run the relevant `just check` / `just test` recipe after changes.
- Record new commands and gotchas in `AGENTS.md`.
