#!/usr/bin/env bash
# --------------------------------------------------------------
# ML4W OS - Dotfiles for Hyprland (FreeBSD) - Installer
# --------------------------------------------------------------
# FreeBSD-only fork. Requires FreeBSD 14.x or 15.x (amd64 recommended).
# Installs the ML4W Hyprland dotfiles using the FreeBSD pkg repository
# and elogind/loginctl for session and power management.
# --------------------------------------------------------------
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_path="$(dirname "$SCRIPT_DIR")"

# Colors
RESET='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'

info() {
    echo -e "${GREEN}::${RESET} $*"
}

warn() {
    echo -e "${YELLOW}:: WARNING:${RESET} $*"
}

error() {
    echo -e "${RED}:: ERROR:${RESET} $*" >&2
}
trap 'if [ $? -ne 0 ]; then error "Installer failed in ${BASH_SOURCE[0]} on line ${LINENO}"; fi' ERR

# --------------------------------------------------------------
# Prerequisites
# --------------------------------------------------------------

check_freebsd() {
    if [ "$(uname -s)" != "FreeBSD" ]; then
        error "This installer is only for FreeBSD. Detected: $(uname -s)"
        exit 1
    fi
    case "$(uname -m)" in
        amd64)
            ;;
        *)
            warn "%s architecture detected. amd64 is recommended." "$(uname -m)"
            ;;
    esac
}

require_root() {
    if [ "$(id -u)" -eq 0 ]; then
        SUDO=""
        return
    fi
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
        info "Root privileges required. Sudo will be used."
        if ! $SUDO -v; then
            error "Unable to acquire sudo privileges."
            exit 1
        fi
    else
        error "Please run this installer as root or install sudo first."
        exit 1
    fi
}

bootstrap_pkg() {
    if command -v pkg &> /dev/null; then
        return
    fi
    info "Bootstrap pkg package manager"
    env ASSUME_ALWAYS_YES=yes pkg bootstrap -f
}

install_packages() {
    local pkg_list="$repo_path/setup/dependencies/packages"
    if [ ! -f "$pkg_list" ]; then
        error "Package list not found: $pkg_list"
        exit 1
    fi
    mapfile -t packages < <(grep -vE '^[[:space:]]*#|^[[:space:]]*$' "$pkg_list")
    info "Installing ${#packages[@]} packages with pkg"

    # Only check for awww if it isn't already installed.
    if ! $SUDO pkg info -e awww >/dev/null 2>&1; then
        # awww is only available on the 'latest' repo branch.
        # Instead of overwriting the default FreeBSD.conf, we add a low-priority
        # latest repo to avoid breaking the system's quarterly branch.
        if ! $SUDO pkg rquery '%n' awww 2>/dev/null | grep -qx awww; then
            warn "awww is not in the current repo branch. Adding low-priority 'latest' repo."
            $SUDO mkdir -p /usr/local/etc/pkg/repos
            $SUDO sh -c "cat > /usr/local/etc/pkg/repos/FreeBSD-Latest.conf <<EOF
FreeBSD-Latest: {
  url: \"pkg+http://pkg.FreeBSD.org/\${ABI}/latest\",
  mirror_type: \"srv\",
  signature_type: \"fingerprints\",
  fingerprints: \"/usr/share/keys/pkg\",
  enabled: yes,
  priority: 0
}
EOF"
            $SUDO pkg update -f
        fi
    fi

    $SUDO pkg install -y "${packages[@]}"
}

install_dotfiles() {
    info "Linking and copying dotfiles to $HOME"
    mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share/ml4w-dotfiles-settings"

    # Symlink core configuration directories for seamless development
    local core_dirs=("ml4w" "hypr" "waybar" "matugen")
    for dir in "${core_dirs[@]}"; do
        ln -sfn "$repo_path/dotfiles/.config/$dir" "$HOME/.config/$dir"
    done

    # Symlink QuickShell settings
    ln -sfn "$repo_path/dotfiles/.config/quickshell" "$HOME/.local/share/ml4w-dotfiles-settings/quickshell"

    # Copy static files
    cp -f "$repo_path/dotfiles/.bashrc" "$HOME/.bashrc"
    cp -f "$repo_path/dotfiles/.zshrc" "$HOME/.zshrc"
    cp -f "$repo_path/dotfiles/.gtkrc-2.0" "$HOME/.gtkrc-2.0"
    cp -f "$repo_path/dotfiles/.Xresources" "$HOME/.Xresources"

    # For other configs in .config, we still use rsync but avoid overwriting our symlinks
    # We exclude the symlinked directories
    rsync -a --exclude={"ml4w","hypr","waybar","matugen"} "$repo_path/dotfiles/.config/" "$HOME/.config/"
}

register_session() {
    if [ ! -f /usr/local/share/wayland-sessions/ml4w.desktop ]; then
        info "Registering Hyprland Wayland session (ml4w.desktop)"
        $SUDO install -d -o root -g wheel /usr/local/share/wayland-sessions
        $SUDO install -m 644 "$repo_path/setup/freebsd/ml4w.desktop" /usr/local/share/wayland-sessions/
    fi
}

# --------------------------------------------------------------
# Main
# --------------------------------------------------------------

check_freebsd
require_root

bootstrap_pkg

info "Installing base packages"
install_packages

info "Running FreeBSD system preflight"
source "$SCRIPT_DIR/preflight-freebsd.sh"

info "Installing dotfiles"
install_dotfiles

info "Running post-installation setup"
source "$SCRIPT_DIR/post-freebsd.sh"

register_session

echo
info "Installation finished."
info "Next steps:"
echo "  1. Reboot your system:                $SUDO shutdown -r now"
echo "  2. Choose 'ML4W OS - Hyprland (FreeBSD)' at the login screen."
echo "  3. Set the wallpaper:                 ml4w-wallpaper"
echo "  4. Update Hyprland to your hardware:  $SUDO sysrc kld_list=... (see preflight)"