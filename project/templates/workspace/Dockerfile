# syntax=docker/dockerfile:1
#
# Workspace image: the base harness plus everything the west projects need.
# Keep project-specific toolchains here, not in the base image.

ARG HIVE_BASE_IMAGE=hive-base:dev
FROM ${HIVE_BASE_IMAGE}

USER root

# --- per-repo extras ---------------------------------------------------------
# Add toolchains required by the projects in manifest/west.yml, for example:
#
#   RUN apt-get update \
#       && apt-get install -y --no-install-recommends <packages> \
#       && rm -rf /var/lib/apt/lists/*
#   RUN npm install -g <tool>
#   RUN python3 -m pip install --break-system-packages <package>
#   RUN cargo install <crate>
#
# Document each addition in AGENTS.md (directory -> package manager).

USER agent
