#!/usr/bin/env bash

# This script monitors changes to the GTK settings.ini file
# and automatically switches the 'matugen' theme between light and dark
# based on the 'gtk-application-prefer-dark-theme' setting.

# Path to the GTK settings file
SETTINGS_FILE="$HOME/.config/gtk-3.0/settings.ini"

# Ensure fswatch is installed (inotifywait is Linux-only)
if ! command -v fswatch &> /dev/null
then
    echo "Error: fswatch is not installed."
    echo "Please install it (FreeBSD: pkg install fswatch)"
    exit 1
fi

echo "Monitoring $SETTINGS_FILE for changes..."
echo "Press Ctrl+C to stop."

# Function to apply the theme based on the current settings
apply_theme() {
    # Check if the settings file exists
    if [ ! -f "$SETTINGS_FILE" ]; then
        echo "Error: $SETTINGS_FILE not found. Please ensure the file exists."
        return 1
    fi

    # Determine matugen binary path
    if [ -f $HOME/.cargo/bin/matugen ]; then
        MATUGEN_BIN="$HOME/.cargo/bin/matugen"
    elif [ -f $HOME/.local/bin/matugen ]; then
        MATUGEN_BIN="$HOME/.local/bin/matugen"
    else
        MATUGEN_BIN="matugen"
    fi

    # Extract the value of gtk-application-prefer-dark-theme
    # We use grep to find the line and awk to get the value after the '='
    THEME_PREF=$(grep -E '^gtk-application-prefer-dark-theme=' "$SETTINGS_FILE" | awk -F'=' '{print $2}')

    if [ -z "$THEME_PREF" ]; then
        echo "Warning: 'gtk-application-prefer-dark-theme' setting not found in $SETTINGS_FILE. Skipping theme application."
        return 0
    fi

    if [[ "$THEME_PREF" == "1" || "$THEME_PREF" == "true" ]]; then
        echo "Detected dark theme preference (gtk-application-prefer-dark-theme=1/true). Applying dark matugen theme..."
        $MATUGEN_BIN image $(cat ~/.cache/ml4w/hyprland-dotfiles/current_wallpaper) --source-color-index 0 -m "dark"

        # Update Quickshell theme
        qs ipc call theme-manager reload
        echo "Quickshell Theme updated"

        # Update ML4W Dotfiles Settings theme
        qs -p $HOME/.local/share/ml4w-dotfiles-settings/quickshell ipc call theme-manager reload
        echo "ML4W Dotfiles Settings Theme updated"

        # Reload Waybar
        nohup bash -c "$HOME/.config/waybar/launch.sh" > /dev/null 2>&1 &
        disown

        $HOME/.config/hypr/scripts/gtk.sh &

        swaync-client -rs
    elif [[ "$THEME_PREF" == "0" || "$THEME_PREF" == "false" ]]; then
        echo "Detected light theme preference (gtk-application-prefer-dark-theme=0/false). Applying light matugen theme..."
        $MATUGEN_BIN image $(cat ~/.cache/ml4w/hyprland-dotfiles/current_wallpaper) --source-color-index 0 -m "light"

        # Update Quickshell theme
        qs ipc call theme-manager reload
        echo "Quickshell Theme updated"

        # Reload Waybar
        nohup bash -c "$HOME/.config/waybar/launch.sh" > /dev/null 2>&1 &
        disown

        $HOME/.config/hypr/scripts/gtk.sh &

        swaync-client -rs
    else
        echo "Warning: Unexpected value for gtk-application-prefer-dark-theme: $THEME_PREF. Expected 0/1/true/false. Skipping theme application."
    fi
}

# Loop indefinitely, reading output from fswatch (kqueue backend on FreeBSD)
fswatch -0 --monitor=kqueue_monitor --event=Updated "$SETTINGS_FILE" | while IFS= read -r -d '' _path; do
    echo "Change detected in $SETTINGS_FILE. Re-applying theme..."
    apply_theme
done