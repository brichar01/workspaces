#!/usr/bin/env bash
# hive-entrypoint: prepare the mounted hive.nvim checkout, then exec the
# requested command. Runs as PID 1's child under tini.
set -euo pipefail

node_dir="${HIVE_NODE_DIR:-/workspace/hive.nvim/node}"

if [ -f "${node_dir}/package.json" ] && [ ! -d "${node_dir}/node_modules" ]; then
    echo "hive-entrypoint: installing node dependencies in ${node_dir}" >&2
    ( cd "${node_dir}" && npm ci --no-audit --no-fund )
fi

exec "$@"
