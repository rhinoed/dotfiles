#!/usr/bin/env bash

BINDINGS_DIR="$HOME/.config/hypr/conf/keybindings"
TMP_BINDS=$(mktemp)

# Find all lines containing hl.bind
grep -r "hl.bind" "$BINDINGS_DIR" --include="*.lua" | while read -r line; do
    # 1. Extract the content inside the first set of parentheses of hl.bind(...)
    # This regex grabs everything between the first ( and the first ,
    if [[ $line =~ hl\.bind\(([^,]+) ]]; then
        raw_combo="${BASH_REMATCH[1]}"
    else
        continue
    fi

    # 2. Clean up the combo string
    # Remove quotes, remove "mainMod .. ", and trim whitespace
    combo=$(echo "$raw_combo" | sed -E 's/mainMod\s*\.\.\s*//g; s/\"//g; s/^\s+//; s/\s+$//')

    # 3. Extract the description
    # Look for description = "..."
    if [[ $line =~ description\ =\ \"([^\"]+)\" ]]; then
        desc="${BASH_REMATCH[1]}"
    else
        desc="No description"
    fi

    # 4. If we found a combo, output it for Rofi
    if [ -n "$combo" ]; then
        # Substitute SUPER if mainMod was replaced but not specified (optional)
        # Since we stripped mainMod, let's prepend SUPER if it looks like a shortcut
        if [[ ! "$combo" =~ ^(SUPER|CTRL|ALT|SHIFT|XF86) ]]; then
            combo="SUPER + $combo"
        fi
        printf "%s\n➔ %s\0" "$combo" "$desc" >> "$TMP_BINDS"
    fi
done

# Launch Rofi
cat "$TMP_BINDS" | rofi -dmenu -i -replace -p "Keybinds" -sep '\0' -eh 2 -config ~/.config/rofi/config-compact.rasi

rm "$TMP_BINDS"
