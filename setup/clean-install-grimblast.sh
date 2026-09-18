#!/usr/bin/env bash
# --------------------------------------------------------------
# Install grimblast on FreeBSD
# --------------------------------------------------------------
# grimblast is a shell script shipped in the hyprwm/contrib repo; no
# compilation is required. It is placed into ~/.local/bin.
# --------------------------------------------------------------

if [ -z "$ML4W_GRIMBLAST_SKIP" ]; then
    GRIMBLAST_BUILD_DIR="$(mktemp -d)"
    trap 'rm -rf "$GRIMBLAST_BUILD_DIR"' EXIT

    if command -v git &> /dev/null; then
        git clone --depth=1 https://github.com/hyprwm/contrib.git "$GRIMBLAST_BUILD_DIR"
    else
        echo ":: ERROR: git is required to install grimblast." >&2
        exit 1
    fi

    if [ -f "$GRIMBLAST_BUILD_DIR/grimblast/grimblast" ]; then
        mkdir -p "$HOME/.local/bin"
        cp "$GRIMBLAST_BUILD_DIR/grimblast/grimblast" "$HOME/.local/bin/grimblast"
        chmod +x "$HOME/.local/bin/grimblast"
        # Remove any conflicting instance in a system path
        if [ -w /usr/local/bin ] && [ -f /usr/local/bin/grimblast ]; then
            rm -f /usr/local/bin/grimblast
        fi
        echo ":: grimblast installed in ~/.local/bin"
    else
        echo ":: ERROR: grimblast source not found." >&2
        exit 1
    fi
fi