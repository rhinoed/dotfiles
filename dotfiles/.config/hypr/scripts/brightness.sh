#!/usr/bin/env bash
# __  ______   ____
# \ \/ /  _ \ / ___|
#  \  /| | | | |  _
#  /  \| |_| | |_| |
# /_/\_\____/ \____|
#

# Backlight wrapper for FreeBSD using base backlight(8).
# No brightnessctl is needed. The invoking user must be in the
# "operator" group (see setup/preflight-freebsd.sh) or use sudo.

STORE="/tmp/.ml4w-hypridle-backlight"

case "${1:-get}" in
    get)
        if [ "$2" = "-q" ]; then
            backlight -q 2>/dev/null
        else
            backlight 2>/dev/null
        fi
        ;;
    set)
        backlight "${2:-100}" 2>/dev/null
        ;;
    min)
        # Store the current level, then dim to 10% (avoid 0 on OLED)
        backlight -q > "$STORE" 2>/dev/null || true
        backlight 10 2>/dev/null
        ;;
    restore)
        if [ -s "$STORE" ]; then
            backlight "$(cat "$STORE")" 2>/dev/null || true
            rm -f "$STORE"
        else
            backlight 100 2>/dev/null
        fi
        ;;
    up|+)
        backlight incr "${2:-5}" 2>/dev/null
        ;;
    down|-)
        backlight decr "${2:-5}" 2>/dev/null
        ;;
    *)
        echo "Usage: brightness.sh {get|set N|min|restore|up|down}" >&2
        exit 1
        ;;
esac