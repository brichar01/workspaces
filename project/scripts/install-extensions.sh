#!/usr/bin/env bash
# workspaces_install_extensions: run every /opt/extensions/<name>/install.sh.
#
# Called from the workspace Dockerfile as root. Each install.sh gets
# EXTENSION_DIR (its own directory) and WORKSPACES_USER (the container user).
set -euo pipefail

shopt -s nullglob
for dir in /opt/extensions/*/; do
    dir="${dir%/}"
    [ -f "${dir}/install.sh" ] || continue
    echo "workspaces_install_extensions: $(basename "${dir}")" >&2
    EXTENSION_DIR="${dir}" bash "${dir}/install.sh"
done
