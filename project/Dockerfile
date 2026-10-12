# syntax=docker/dockerfile:1

###############################################################################
# workspaces base image
#
# Universal dependencies only, with no agents. Agents and other development
# tools are extensions (see extensions/). Per-repo toolchains belong in the
# workspace Dockerfile that extends this image.
#
# Build context: this directory (the project template repo).
###############################################################################
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG USERNAME=workspaces_user
ARG HOST_UID=1000
ARG HOST_GID=1000
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
    && curl -fsSL https://just.systems/install.sh \
        | bash -s -- --to /usr/local/bin --tag "${JUST_VERSION}" \
    && python3 -m pip install --no-cache-dir --break-system-packages "west==${WEST_VERSION}" \
    && rm -rf /var/lib/apt/lists/* /root/.cache

# --- non-root user (distrobox-style UID/GID match) ---------------------------
# ubuntu:24.04 already ships an 'ubuntu' user at UID/GID 1000; remove it so the
# workspace user is the only owner of those ids. -o tolerates other collisions.
RUN set -eux; \
    if [ "${HOST_UID}" != "0" ]; then \
        userdel -r ubuntu >/dev/null 2>&1 || true; \
        groupdel ubuntu >/dev/null 2>&1 || true; \
        groupadd -o -g "${HOST_GID}" "${USERNAME}"; \
        useradd -o -m -u "${HOST_UID}" -g "${USERNAME}" -s /bin/bash "${USERNAME}"; \
        echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}"; \
        chmod 0440 "/etc/sudoers.d/${USERNAME}"; \
    fi

# --- helper scripts ----------------------------------------------------------
COPY scripts/entrypoint.sh         /usr/local/bin/workspaces_entrypoint
COPY scripts/doctor.sh             /usr/local/bin/workspaces_doctor
COPY scripts/install-extensions.sh /usr/local/bin/workspaces_install_extensions
RUN chmod 0755 /usr/local/bin/workspaces_entrypoint \
        /usr/local/bin/workspaces_doctor \
        /usr/local/bin/workspaces_install_extensions \
    && install -d -m 0755 /opt/extensions

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    WORKSPACES_USER=${USERNAME}

WORKDIR /workspace
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/workspaces_entrypoint"]
CMD ["bash"]
