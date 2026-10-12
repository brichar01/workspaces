#!/usr/bin/env bash
# Install Claude Code and link its curated config into the workspace user's home.
set -euo pipefail

CLAUDE_CODE_VERSION="${CLAUDE_CODE_VERSION:-2.1.296}"
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

# Claude Code needs its install scripts, unlike Pi.
npm install -g "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}"
npm cache clean --force
rm -rf /root/.npm

home="$(getent passwd "${WORKSPACES_USER}" | cut -d: -f6)"
mkdir -p "${home}/.claude"
for file in settings.json CLAUDE.md; do
    ln -sf "${EXTENSION_DIR}/config/${file}" "${home}/.claude/${file}"
done
chown -R "${WORKSPACES_USER}:${WORKSPACES_USER}" "${home}/.claude"
