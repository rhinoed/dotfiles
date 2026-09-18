#!/usr/bin/env bash
# __  ______   ____
# \ \/ /  _ \ / ___|
#  \  /| | | | |  _
#  /  \| |_| | |_| |
# /_/\_\____/ \____|
#

# Start the first available polkit authentication agent.
# FreeBSD ships hyprpolkitagent (sysutils/hyprpolkitagent); the polkit-gnome
# fallback covers other setups. Binaries may live outside $PATH.

agent=""
for candidate in hyprpolkitagent polkit-gnome-authentication-agent-1 lxqt-policykit-agent; do
    if command -v "$candidate" >/dev/null 2>&1; then
        agent="$candidate"
        break
    elif [ -x "/usr/local/libexec/$candidate" ]; then
        agent="/usr/local/libexec/$candidate"
        break
    fi
done

if [ -n "$agent" ] && ! pgrep -f "$(basename "$agent")" >/dev/null 2>&1; then
    "$agent" &
fi
exit 0