# Sourced by workspaces_doctor.
have node && ok "node present ($(node --version))" || bad "node missing"
have pi && ok "pi present" || bad "pi missing"
if [ -e "${HOME}/.pi/agent/settings.json" ]; then
    ok "pi config: ${HOME}/.pi/agent/settings.json"
else
    warnf "pi config missing: ${HOME}/.pi/agent/settings.json"
fi
