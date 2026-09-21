#!/usr/bin/env bash

BINDINGS_DIR="$HOME/.config/hypr/conf/keybindings"
TMP_BINDS=$(mktemp)

# Parse all .lua files in the keybindings directory
grep -r "hl.bind" "$BINDINGS_DIR" --include="*.lua" | while read -r line; do
    # 1. Extract the key combination (1st arg)
    if [[ $line =~ hl\.bind\(([^,]+), ]]; then
        raw_combo="${BASH_REMATCH[1]}"
    else
        continue
    fi

    # Clean up the combo string
    combo="${raw_combo//\"/}"
    combo="${combo//mainMod .. /}"
    combo="${combo#"${combo%%[![:space:]]*}"}"
    combo="${combo%"${combo##*[![:space:]]}"}"
    if [[ ! "$combo" =~ ^(SUPER|CTRL|ALT|SHIFT|XF86) ]]; then
        combo="SUPER + $combo"
    fi

    # 2. Extract the command (2nd arg)
    # This looks for the content between the first and second comma
    if [[ $line =~ hl\.bind\([^,]+,\s*([^,]+), ]]; then
        raw_cmd="${BASH_REMATCH[1]}"
    else
        continue
    fi

    # Clean up the command
    # Handle hl.dsp.exec_cmd("...") or hl.dsp.focus(...)
    if [[ "$raw_cmd" =~ hl\.dsp\.exec_cmd\(\"([^\"]+)\"\) ]]; then
        cmd="${BASH_REMATCH[1]}"
    elif [[ "$raw_cmd" =~ hl\.dsp\.window\.move\(\{.*workspace\ =\ ([0-9]+)\}.*\}\) ]]; then
        # Example: move to workspace 1 -> hyprctl dispatch movetoworkspace 1
        ws="${BASH_REMATCH[1]}"
        cmd="hyprctl dispatch movetoworkspace $ws"
    elif [[ "$raw_cmd" =~ hl\.dsp\.focus\(\{.*workspace\ =\ ([0-9]+)\}.*\}\) ]]; then
        ws="${BASH_REMATCH[1]}"
        cmd="hyprctl dispatch workspace $ws"
    else
        # Fallback: just use the raw string or a generic notification
        cmd="echo 'Command not supported for direct execution'"
    fi

    # 3. Extract the description
    if [[ $line =~ description\ =\ \"([^\"]+)\" ]]; then
        desc="${BASH_REMATCH[1]}"
    else
        desc="No description"
    fi

    # Output: Label (for display) \0 Command (to be returned)
    printf "%s - %s\0%s\0" "$combo" "$desc" "$cmd" >> "$TMP_BINDS"
done

# Launch Rofi and capture the selected command
SELECTED_CMD=$(cat "$TMP_BINDS" | rofi -dmenu -i -replace -p "Keybinds" -sep '\0' -eh 2 -config ~/.config/rofi/config-compact.rasi)

# Execute the command if one was selected
if [ -n "$SELECTED_CMD" ]; then
    eval "$SELECTED_CMD" &
fi

rm "$TMP_BINDS"
