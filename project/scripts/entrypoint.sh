#!/usr/bin/env bash
# workspaces_entrypoint: run each installed extension's start hooks, then exec
# the requested command. Runs as PID 1's child under tini.
#
# Hooks are /opt/extensions/<name>/entrypoint.d/*.sh, run in lexical order as
# the container user. A failing hook stops the container.
set -euo pipefail

shopt -s nullglob
for hook in /opt/extensions/*/entrypoint.d/*.sh; do
    echo "workspaces_entrypoint: ${hook}" >&2
    bash "${hook}"
done
shopt -u nullglob

exec "$@"
