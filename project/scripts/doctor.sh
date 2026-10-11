#!/usr/bin/env bash
# hive-doctor: verify the workspace and harness are healthy.
#
# Runs both on the host (after `west init`) and inside the container.
# Usage: hive-doctor [--quick]
set -uo pipefail

quick=0
[ "${1:-}" = "--quick" ] && quick=1

pass=0
fail=0
warn=0

ok()   { printf '  \033[32mok\033[0m   %s\n' "$1"; pass=$((pass + 1)); }
bad()  { printf '  \033[31mFAIL\033[0m %s\n' "$1"; fail=$((fail + 1)); }
warnf(){ printf '  \033[33mwarn\033[0m %s\n' "$1"; warn=$((warn + 1)); }

have() { command -v "$1" >/dev/null 2>&1; }

echo "hive-doctor: $(pwd)"

# --- tools -------------------------------------------------------------------
for tool in git just; do
    have "${tool}" && ok "${tool} present" || bad "${tool} missing"
done
have west && ok "west present" || warnf "west missing (host-side requirement)"

# --- workspace ---------------------------------------------------------------
if [ -f manifest/west.yml ]; then
    ok "manifest/west.yml present"
    if have west; then
        if [ -d .west ]; then
            ok ".west initialized"
            if [ "${quick}" -eq 0 ]; then
                if west manifest --validate >/dev/null 2>&1; then
                    ok "west manifest valid"
                else
                    bad "west manifest invalid (run: west manifest --validate)"
                fi
                missing=0
                while read -r path; do
                    [ -z "${path}" ] && continue
                    [ -e "${path}" ] || { bad "missing west project at ${path} (run: west update)"; missing=1; }
                done < <(west list -f '{path}' 2>/dev/null || true)
                [ "${missing}" -eq 0 ] && ok "all west projects present"
            fi
        else
            bad ".west missing (run: just init)"
        fi
    fi
else
    bad "manifest/west.yml missing"
fi

# --- harness (container) -----------------------------------------------------
if [ -d /workspace ]; then
    have node && ok "node present ($(node --version 2>/dev/null))" || bad "node missing"
    have pi   && ok "pi present"   || bad "pi missing"
    have claude && ok "claude present" || warnf "claude present: no"
    [ -n "${PI_CODING_AGENT_DIR:-}" ] && ok "PI_CODING_AGENT_DIR=${PI_CODING_AGENT_DIR}" || warnf "PI_CODING_AGENT_DIR unset"

    for link in "${PI_CODING_AGENT_DIR:-/home/agent/.pi/agent}/settings.json" \
                "${HOME:-/home/agent}/.claude/settings.json"; do
        if [ -e "${link}" ]; then
            ok "config: ${link}"
        else
            warnf "config missing: ${link}"
        fi
    done

    if have node && [ -f "${HIVE_NODE_DIR:-/workspace/hive.nvim/node}/src/main.ts" ]; then
        ok "hive node entrypoint present"
    else
        warnf "hive node entrypoint not found at ${HIVE_NODE_DIR:-/workspace/hive.nvim/node}"
    fi

    if [ "${quick}" -eq 0 ] && have bash; then
        if (exec 3<>/dev/tcp/127.0.0.1/7777) 2>/dev/null; then
            ok "hive agent TCP service reachable on 127.0.0.1:7777"
        else
            warnf "hive agent TCP service not reachable on 127.0.0.1:7777"
        fi
    fi
fi

echo
printf 'hive-doctor: %d ok, %d warnings, %d failures\n' "${pass}" "${warn}" "${fail}"
[ "${fail}" -eq 0 ]
