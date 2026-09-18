#!/usr/bin/env bash
# --------------------------------------------------------------
# Fonts (FreeBSD: /usr/local/share/fonts)
# --------------------------------------------------------------

FONT_DIR="${FONT_DIR:-/usr/local/share/fonts}"
SUDO="${SUDO:-}"

${SUDO} mkdir -p "$FONT_DIR/FiraCode" "$FONT_DIR/Fira_Sans" "$FONT_DIR/Material-Icons"
BUNDLED_FONTS="$repo_path/setup/fonts"
for font in FiraCode Fira_Sans Material-Icons; do
    if [ -d "$BUNDLED_FONTS/$font" ]; then
        ${SUDO} cp -rf "$BUNDLED_FONTS/$font/." "$FONT_DIR/$font/"
    fi
done

if command -v fc-cache &> /dev/null; then
    fc-cache -f
fi