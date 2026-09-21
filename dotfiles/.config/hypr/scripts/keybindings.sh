#!/usr/bin/env bash

BINDINGS_DIR="$HOME/.config/hypr/conf/keybindings"
TMP_BINDS=$(mktemp)

# Find all lines containing hl.bind
grep -r "hl.bind" "$BINDINGS_DIR" --include="*.lua" | while read -r line; do
    # 1. Extract the content inside the first set of parentheses: hl.bind(...)
    # Using bash regex to get the first argument
    if [[ $line =~ hl\.bind\(([^,]+) ]]; then
        raw_combo="${BASH_REMATCH[1]}"
    else
        continue
    fi

    # 2. Clean up the combo string using Bash parameter expansion
    # Remove quotes
    combo="${raw_combo//\"/}"
    # Remove "mainMod .."
    combo="${combo//mainMod .. /}"
    # Trim leading/trailing whitespace
    combo="${combo#"${combo%%[![:space:]]*}"}"
    combo="${combo%"${combo##*[![:space:]]}"}"

    # 3. Extract the description
    if [[ $line =~ description\ =\ \"([^\"]+)\" ]]; then
        desc="${BASH_REMATCH[1]}"
    else
        desc="No description"
    fi

    # 4. Final polish: if it starts with a common key but no modifier, assume SUPER
    if [[ -n "$combo" ]]; then
        if [[ ! "$combo" =~ ^(SUPER|CTRL|ALT|SHIFT|XF86) ]]; then
            combo="SUPER + $combo"
        fi
        printf "%s\n➔ %s\0" "$combo" "$desc" >> "$TMP_BINDS"
    fi
done

# Launch Rofi
cat "$TMP_BINDS" | rofi -dmenu -i -replace -p "Keybinds" -sep '\0' -eh 2 -config ~/.config/rofi/config-compact.rasi

rm "$TMP_BINDS"
