#!/usr/bin/env bash
#
# engine.sh: the single place that knows about Docker vs Podman and about the
# devcontainer CLI. Everything else in the workspace goes through it.
#
# Usage: engine.sh <command> [args...]
#
#   preflight            validate the engine and create .env if missing
#   ensure-base          build the base image from HIVE_PROJECT_DIR if absent
#   up                   start the workspace (devcontainer CLI, else compose)
#   up --compose         force the raw compose path
#   down                 stop and remove the stack
#   rebuild              recreate the container from scratch
#   exec <cmd...>        run a command in the running container
#   logs [service...]    follow logs
#   ps                   list containers
#   compose <args...>    raw engine compose passthrough
set -euo pipefail

ENGINE="${CONTAINER_ENGINE:-podman}"
DEVCONTAINER="${DEVCONTAINER:-devcontainer}"
HOST_UID="$(id -u)"
HOST_GID="$(id -g)"
export HOST_UID HOST_GID

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

# Pick up .env (HIVE_BASE_IMAGE, HIVE_PROJECT_DIR, credentials, ...).
if [ -f .env ]; then
    set -a
    # shellcheck disable=SC1091
    . ./.env
    set +a
fi

base_image="${HIVE_BASE_IMAGE:-hive-base:dev}"
project_dir="${HIVE_PROJECT_DIR:-../project}"

compose_args=(-f compose.yaml -f compose.override.yaml)
dc_args=(--workspace-folder .)
if [ "$ENGINE" = "podman" ]; then
    compose_args+=(-f compose.podman.yaml)
    dc_args+=(--override-config .devcontainer/devcontainer.podman.json)
    export DOCKER_HOST="${DOCKER_HOST:-unix:///run/user/${HOST_UID}/podman/podman.sock}"
fi

have_dc() {
    command -v "$DEVCONTAINER" >/dev/null 2>&1 && [ -f .devcontainer/devcontainer.json ]
}

compose() { "$ENGINE" compose "${compose_args[@]}" "$@"; }

ensure_env() {
    if [ ! -f .env ]; then
        if [ -f .env.example ]; then
            cp .env.example .env
            echo "engine.sh: created .env from .env.example (add credentials there)" >&2
        else
            : > .env
        fi
    fi
}

preflight() {
    command -v "$ENGINE" >/dev/null 2>&1 || { echo "engine '$ENGINE' not found" >&2; exit 1; }
    if [ "$ENGINE" = "podman" ]; then
        systemctl --user start podman.socket >/dev/null 2>&1 || true
        podman info >/dev/null 2>&1 || { echo "podman not usable" >&2; exit 1; }
    else
        "$ENGINE" info >/dev/null 2>&1 || { echo "docker daemon not reachable" >&2; exit 1; }
    fi
    ensure_env
    if have_dc; then
        "$DEVCONTAINER" --version >/dev/null
        echo "engine.sh: using $ENGINE + devcontainer CLI"
    else
        compose version >/dev/null
        echo "engine.sh: using $ENGINE + raw compose (devcontainer CLI not found)"
    fi
}

ensure_base() {
    if [ -n "$("$ENGINE" images -q "$base_image" 2>/dev/null)" ]; then
        return 0
    fi
    if [ -f "${project_dir}/Dockerfile" ]; then
        echo "engine.sh: building base image ${base_image} from ${project_dir}" >&2
        "$ENGINE" build -t "$base_image" -f "${project_dir}/Dockerfile" "$project_dir"
    else
        echo "engine.sh: base image ${base_image} missing and ${project_dir}/Dockerfile not found." >&2
        echo "           set HIVE_PROJECT_DIR or run 'just base' in the project repo." >&2
        exit 1
    fi
}

up() {
    ensure_env
    if [ "${1:-}" != "--compose" ] && have_dc; then
        "$DEVCONTAINER" up "${dc_args[@]}"
    else
        compose up -d
    fi
}

down() { compose down; }

rebuild() {
    if have_dc; then
        "$DEVCONTAINER" up "${dc_args[@]}" --remove-existing-container
    else
        compose build --no-cache agent
        compose up -d --force-recreate
    fi
}

exec_cmd() {
    [ "$#" -gt 0 ] || { echo "engine.sh exec: missing command" >&2; exit 2; }
    if have_dc; then
        "$DEVCONTAINER" exec "${dc_args[@]}" "$@"
    else
        compose exec agent "$@"
    fi
}

case "${1:-}" in
    preflight)   shift; preflight "$@" ;;
    ensure-base) shift; ensure_base "$@" ;;
    up)          shift; up "$@" ;;
    down)        shift; down "$@" ;;
    rebuild)     shift; rebuild "$@" ;;
    exec)        shift; exec_cmd "$@" ;;
    logs)        shift; compose logs -f "$@" ;;
    ps)          shift; compose ps "$@" ;;
    compose)     shift; compose "$@" ;;
    *)
        sed -n '3,20p' "$0" | sed 's/^# \{0,1\}//'
        exit 2
        ;;
esac
