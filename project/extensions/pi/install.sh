#!/usr/bin/env bash
# Install Pi and link its curated config into the workspace user's home.
set -euo pipefail

PI_VERSION="${PI_VERSION:-1.1.0}"
NODE_MAJOR="${NODE_MAJOR:-24}"

if ! command -v npm >/dev/null 2>&1; then
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
        | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" \
        > /etc/apt/sources.list.d/nodesource.list
    apt-get update
    apt-get install -y --no-install-recommends nodejs
    rm -rf /var/lib/apt/lists/*
fi

# Installed without lifecycle scripts, per Pi's containerisation guide.
npm install -g --ignore-scripts "@earendil-works/pi-coding-agent@${PI_VERSION}"
npm cache clean --force
rm -rf /root/.npm

home="$(getent passwd "${WORKSPACES_USER}" | cut -d: -f6)"
mkdir -p "${home}/.pi/agent"
for file in settings.json models.json mcp.json AGENTS.md; do
    ln -sf "${EXTENSION_DIR}/config/${file}" "${home}/.pi/agent/${file}"
done
chown -R "${WORKSPACES_USER}:${WORKSPACES_USER}" "${home}/.pi"
