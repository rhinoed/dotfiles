#!/usr/bin/env bash
# __  ______   ____
# \ \/ /  _ \ / ___|
#  \  /| | | | |  _
#  /  \| |_| | |_| |
# /_/\_\____/ \____|
#

# FreeBSD/elogind helper: (re)start the audio + XDG desktop portal stack.
# Used by autostart.lua and xdg.sh whenever the session environment changes.

# Resolve a binary that may live outside $PATH (/usr/local/libexec is the
# default install prefix for the FreeBSD portal/hyprland packages).
locate() {
    if command -v "$1" >/dev/null 2>&1; then
        command -v "$1"
    elif [ -x "/usr/local/libexec/$1" ]; then
        echo "/usr/local/libexec/$1"
    fi
}

_sleep1="0.1"
_sleep3="2"

# Start pipewire + wireplumber if not already running (no systemd user
# services on FreeBSD).
if ! pgrep -x pipewire >/dev/null 2>&1; then
    pipewire &
fi
sleep "$_sleep1"
if ! pgrep -x wireplumber >/dev/null 2>&1; then
    wireplumber &
    sleep "$_sleep3"
fi

# Kill all possible running xdg-desktop-portals
killall -q xdg-desktop-portal-hyprland 2>/dev/null
killall -q xdg-desktop-portal-gtk 2>/dev/null
killall -q xdg-desktop-portal 2>/dev/null

# Push the session environment to D-Bus (no --systemd on FreeBSD)
dbus-update-activation-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

sleep "$_sleep1"

# D-Bus reactivates the portals on demand; start them explicitly as well so
# file pickers and screen sharing work on first use.
for portal in xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-desktop-portal; do
    bin="$(locate "$portal")"
    if [ -n "$bin" ] && ! pgrep -x "$portal" >/dev/null 2>&1; then
        "$bin" &
        sleep "$_sleep1"
    fi
done