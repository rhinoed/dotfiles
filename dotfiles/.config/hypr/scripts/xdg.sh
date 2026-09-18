#!/usr/bin/env bash
# __  ______   ____
# \ \/ /  _ \ / ___|
#  \  /| | | | |  _
#  /  \| |_| | |_| |
# /_/\_\____/ \____|
#

# Setup Timers
_sleep1="0.1"
_sleep2="0.5"
_sleep3="2"
_sleep4="1"

sleep $_sleep4

# Kill all possible running xdg-desktop-portals (pkill is verbose-safe on FreeBSD)
pkill -f xdg-desktop-portal-hyprland 2>/dev/null
pkill -f xdg-desktop-portal-gnome 2>/dev/null
pkill -f xdg-desktop-portal-kde 2>/dev/null
pkill -f xdg-desktop-portal-lxqt 2>/dev/null
pkill -f xdg-desktop-portal-wlr 2>/dev/null
pkill -f xdg-desktop-portal-gtk 2>/dev/null
pkill -f xdg-desktop-portal 2>/dev/null

# Set required environment variables (no --systemd on FreeBSD)
dbus-update-activation-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=hyprland

sleep $_sleep1

# Restart pipewire/wireplumber and (re)activate the portals via the FreeBSD helper
~/.config/hypr/scripts/restart-portals.sh

# Run waybar
sleep $_sleep3
# ~/.config/waybar/launch.sh