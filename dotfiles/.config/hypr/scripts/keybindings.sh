#!/usr/bin/env bash

# Path to keybindings configuration
BINDINGS_DIR="$HOME/.config/hypr/conf/keybindings"

# Temporary file to store extracted binds
TMP_BINDS=$(mktemp)

# Parse all .lua files in the keybindings directory
# We look for lines with hl.bind(..., { description = "..." })
grep -r "hl.bind" "$BINDINGS_DIR" --include="*.lua" | while read -r line; do
    # Extract the key combination
    # Matches the first argument of hl.bind: hl.bind("SUPER + RETURN", ...
    if [[ $line =~ hl\.bind\(\"([^\"]+)\" ]]; then
        combo="${BASH_REMATCH[1]}"
    else
        continue
    fi

    # Extract the description
    # Matches description = "..."
    if [[ $line =~ description\ =\ \"([^\"]+)\" ]]; then
        desc="${BASH_REMATCH[1]}"
    else
        desc="No description"
    fi

    # Output in the format Rofi expects: Key \n ➔ Description \0
    printf "%s\n➔ %s\0" "$combo" "$desc" >> "$TMP_BINDS"
done

# Launch Rofi using the extracted data
cat "$TMP_BINDS" | rofi -dmenu -i -replace -p "Keybinds" -sep '\0' -eh 2 -config ~/.config/rofi/config-compact.rasi

# Cleanup
rm "$TMP_BINDS"
