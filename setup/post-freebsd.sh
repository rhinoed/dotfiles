#!/usr/bin/env bash
# --------------------------------------------------------------
# FreeBSD post-installation, user-level setup
# --------------------------------------------------------------
# Sourced by setup/setup.sh. Uses $repo_path (dotfiles repo root),
# $SUDO (may be empty) and the functions defined in setup.sh.
# --------------------------------------------------------------

info "Running user-level post-installation setup"

# --------------------------------------------------------------
# Oh My Posh
# --------------------------------------------------------------

if ! command -v oh-my-posh &> /dev/null && [ ! -f "$HOME/.local/bin/oh-my-posh" ]; then
    info "Installing Oh My Posh"
    curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"
fi

# --------------------------------------------------------------
# Matugen (built from source via cargo; no FreeBSD package exists)
# --------------------------------------------------------------

if ! command -v matugen &> /dev/null && [ ! -f "$HOME/.local/bin/matugen" ]; then
    info "Installing matugen via cargo (this may take a few minutes)"
    cargo install matugen
fi

# --------------------------------------------------------------
# Pywalfox (wallpaper-driven firefox theming)
# --------------------------------------------------------------

if command -v pipx &> /dev/null && ! command -v pywalfox &> /dev/null; then
    info "Installing pywalfox with pipx"
    pipx install pywalfox
    pywalfox install
fi

# --------------------------------------------------------------
# Grimblast (screenshot tool used by ML4W; no FreeBSD package)
# --------------------------------------------------------------

if ! command -v grimblast &> /dev/null && [ ! -f "$HOME/.local/bin/grimblast" ]; then
    source "$repo_path/setup/clean-install-grimblast.sh"
fi

# --------------------------------------------------------------
# Cursors
# --------------------------------------------------------------

source "$repo_path/setup/_cursors.sh"

# --------------------------------------------------------------
# Fonts
# --------------------------------------------------------------

source "$repo_path/setup/_fonts.sh"

# --------------------------------------------------------------
# Icons
# --------------------------------------------------------------

source "$repo_path/setup/_icons.sh"

# --------------------------------------------------------------
# Refresh font cache
# --------------------------------------------------------------

if command -v fc-cache &> /dev/null; then
    info "Refreshing font cache"
    fc-cache -f
fi

# --------------------------------------------------------------
# Create XDG directories (xdg-user-dirs is not available on FreeBSD)
# --------------------------------------------------------------

mkdir -p "$HOME/Downloads" "$HOME/Documents" "$HOME/Pictures" "$HOME/Videos" "$HOME/Music" "$HOME/Templates" "$HOME/Public"

info "Post-installation setup done."