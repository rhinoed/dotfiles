import Quickshell
import Quickshell.Io
import QtQuick

// Toggles the SwayNotificationCenter panel. Shows a filled bell while there
// are pending notifications.
BarButton {
    id: swaync

    property bool hasNotifications: false

    iconSrc: hasNotifications
        ? "../shared/icons/bell-filled.svg"
        : "../shared/icons/bell.svg"

    onClicked: {
        Quickshell.execDetached(["bash", "-c", "~/.config/ml4w/scripts/ml4w-nc-toggle toggle"])
        swaync.hasNotifications = false
    }

    // Count notification files from swaync's notification cache
    Process {
        id: swayncProc
        command: ["bash", "-c", "ls ~/.cache/swaync/*.json 2>/dev/null | wc -l || echo 0"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    var count = parseInt(data.trim())
                    swaync.hasNotifications = count > 0
                } catch (e) {
                    swaync.hasNotifications = false
                }
            }
        }
    }
}
