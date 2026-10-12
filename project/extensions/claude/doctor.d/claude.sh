# Sourced by workspaces_doctor.
have node && ok "node present ($(node --version))" || bad "node missing"
have claude && ok "claude present" || bad "claude missing"
if [ -e "${HOME}/.claude/settings.json" ]; then
    ok "claude config: ${HOME}/.claude/settings.json"
else
    warnf "claude config missing: ${HOME}/.claude/settings.json"
fi
