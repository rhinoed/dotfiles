#!/bin/bash

# Notifications
source "$HOME/.config/ml4w/scripts/ml4w-notification-handler"
APP_NAME="System"
NOTIFICATION_ICON="battery-low-symbolic"

# FreeBSD ACPI battery (acpiconf). Exit if no battery is present.
if ! acpiconf -i 0 >/dev/null 2>&1; then
    exit 0
fi

NOTIFIED_20=false
NOTIFIED_15=false

while true; do
    CAPACITY=$(acpiconf -i 0 2>/dev/null | awk -F: '/Remaining capacity/{gsub(/[ %\t]/,"",$2); print $2}')
    STATUS=$(acpiconf -i 0 2>/dev/null | awk -F: '/^State:/{print tolower($2)}' | tr -d '[:space:]')

    if [[ -z "$CAPACITY" ]]; then
        exit 0
    fi

    if [[ "$STATUS" == "discharging" ]]; then
        if [[ $CAPACITY -le 15 && $NOTIFIED_15 == false ]]; then
            notify_user \
                --u "critical" \
                --a "${APP_NAME}" \
                --i "${NOTIFICATION_ICON}" \
                --s "Battery Low" \
                --m "Remaining: ${CAPACITY}%"
            NOTIFIED_15=true
        elif [[ $CAPACITY -le 20 && $CAPACITY -gt 15 && $NOTIFIED_20 == false ]]; then
            notify_user \
                --u "normal" \
                --a "${APP_NAME}" \
                --i "${NOTIFICATION_ICON}" \
                --s "Battery Low" \
                --m "Remaining: ${CAPACITY}%"
            NOTIFIED_20=true
        elif [[ $CAPACITY -gt 20 ]]; then
            NOTIFIED_20=false
            NOTIFIED_15=false
        fi
    else
        NOTIFIED_20=false
        NOTIFIED_15=false
    fi

    sleep 60
done
