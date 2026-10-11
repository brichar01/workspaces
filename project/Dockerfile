# syntax=docker/dockerfile:1

###############################################################################
# hive base image
#
# Universal dependencies for the harness only. Per-workspace and per-repo
# toolchains belong in the workspace Dockerfile that extends this image.
#
# Build context: this directory (the project template repo).
###############################################################################
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG USERNAME=agent
ARG HOST_UID=1000
ARG HOST_GID=1000
ARG NODE_MAJOR=24
ARG PI_VERSION=1.1.0
ARG CLAUDE_CODE_VERSION=2.1.296
ARG WEST_VERSION=1.5.0
ARG JUST_VERSION=1.58.0

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# --- OS packages -------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        bash \
        build-essential \
        ca-certificates \
        curl \
        git \
        gnupg \
        jq \
        less \
        make \
        openssh-client \
        python3 \
        python3-pip \
        python3-venv \
        ripgrep \
        software-properties-common \
        sudo \
        tini \
        unzip \
        xz-utils \
    && install -d -m 0755 /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
        | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" \
        > /etc/apt/sources.list.d/nodesource.list \
    && curl -fsSL https://just.systems/install.sh \
        | bash -s -- --to /usr/local/bin --tag "${JUST_VERSION}" \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && python3 -m pip install --no-cache-dir --break-system-packages "west==${WEST_VERSION}" \
    && rm -rf /var/lib/apt/lists/* /root/.cache /root/.npm

# --- AI harnesses ------------------------------------------------------------
# Pi per the containerization guide (no lifecycle scripts). Claude Code needs
# its install scripts, so it is installed separately.
RUN npm install -g --ignore-scripts "@earendil-works/pi-coding-agent@${PI_VERSION}" \
    && npm install -g "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
    && npm cache clean --force

# --- non-root user (distrobox-style UID/GID match) ---------------------------
# ubuntu:24.04 already ships an 'ubuntu' user at UID/GID 1000; remove it so the
# agent user is the only owner of those ids. -o tolerates other collisions.
RUN set -eux; \
    if [ "${HOST_UID}" != "0" ]; then \
        userdel -r ubuntu >/dev/null 2>&1 || true; \
        groupdel ubuntu >/dev/null 2>&1 || true; \
        groupadd -o -g "${HOST_GID}" "${USERNAME}"; \
        useradd -o -m -u "${HOST_UID}" -g "${USERNAME}" -s /bin/bash "${USERNAME}"; \
        echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}"; \
        chmod 0440 "/etc/sudoers.d/${USERNAME}"; \
    fi

# --- curated agent config (NEVER credentials) --------------------------------
# Credentials are passed as environment variables at run time, never baked in.
# Mount a workspace ./config/agent over /opt/agent-config to override locally.
COPY config/agent/ /opt/agent-config/
RUN set -eux; \
    agent_home="/home/${USERNAME}"; \
    mkdir -p "${agent_home}/.pi/agent" "${agent_home}/.claude"; \
    ln -sf /opt/agent-config/pi/settings.json     "${agent_home}/.pi/agent/settings.json"; \
    ln -sf /opt/agent-config/pi/models.json       "${agent_home}/.pi/agent/models.json"; \
    ln -sf /opt/agent-config/pi/mcp.json          "${agent_home}/.pi/agent/mcp.json"; \
    ln -sf /opt/agent-config/pi/AGENTS.md         "${agent_home}/.pi/agent/AGENTS.md"; \
    ln -sf /opt/agent-config/claude/settings.json "${agent_home}/.claude/settings.json"; \
    ln -sf /opt/agent-config/claude/CLAUDE.md     "${agent_home}/.claude/CLAUDE.md"; \
    chown -R "${USERNAME}:${USERNAME}" "${agent_home}"

# --- helper scripts ----------------------------------------------------------
COPY scripts/hive-entrypoint.sh /usr/local/bin/hive-entrypoint
COPY scripts/doctor.sh          /usr/local/bin/hive-doctor
RUN chmod 0755 /usr/local/bin/hive-entrypoint /usr/local/bin/hive-doctor

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PI_CODING_AGENT_DIR=/home/${USERNAME}/.pi/agent \
    HIVE_NODE_DIR=/workspace/hive.nvim/node

WORKDIR /workspace
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/hive-entrypoint"]
CMD ["bash"]
