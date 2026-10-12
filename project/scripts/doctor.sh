#!/usr/bin/env bash
# workspaces_doctor: verify the workspace and its extensions are healthy.
#
# Runs both on the host (after `west init`) and inside the container.
# Usage: workspaces_doctor [--quick]
#
# Each extension can add checks as /opt/extensions/<name>/doctor.d/*.sh. They
# are sourced, so they can call ok, bad, warnf and have, and read $quick.
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

echo "workspaces_doctor: $(pwd)"

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

# --- extensions --------------------------------------------------------------
shopt -s nullglob
for check in /opt/extensions/*/doctor.d/*.sh; do
    # shellcheck disable=SC1090
    . "${check}"
done
shopt -u nullglob

echo
printf 'workspaces_doctor: %d ok, %d warnings, %d failures\n' "${pass}" "${warn}" "${fail}"
[ "${fail}" -eq 0 ]
