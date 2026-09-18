# ML4W Dotfiles for Hyprland on FreeBSD

This is a FreeBSD port of [ML4W Dotfiles for Hyprland](https://github.com/mylinuxforwork/dotfiles).
It targets **FreeBSD 14.x / 15.x** and ships only the FreeBSD installer and the
FreeBSD-native configuration. Linux/AUR/NetworkManager-specific code was removed.

## Requirements

- FreeBSD 14.0+ (amd64 recommended)
- A GPU supported by `drm-kmod` (Intel/AMD) or the NVIDIA driver
- An account with `pw groupmod wheel -m <user>` rights (`sudo`)
- Network access (wired, or a Wi-Fi chip supported by FreeBSD)

## Installation

```sh
su -                        # root
pkg install -y git curl bash sudo
exit                        # back to your user
git clone https://github.com/mylinuxforwork/dotfiles ~/hyprland_config/ml4w/dotfiles
~/hyprland_config/ml4w/dotfiles/setup.sh
```

The installer:

1. Bootstraps `pkg` and installs all packages (`setup/dependencies/packages`).
2. Runs `setup/preflight-freebsd.sh`: GPU kernel modules (`kld_list`), rc.conf
   services (dbus, elogind, wpa_supplicant), PAM (`pam_elogind`), login shells,
   and user groups (`video`, `operator`, `wheel`).
3. Copies the dotfiles into `~/.config` and runs the user-level setup
   (`setup/post-freebsd.sh`): Oh My Posh, matugen (cargo), pywalfox, grimblast,
   cursors, fonts, icons.
4. Installs the SDDM display manager when selected (`ml4w-install-sddm`),
   allowing login from SDDM or from the console (`loginctl login`).

Reboot after installation, then log in with your user via SDDM or console.

## Deviations from the Linux version

| Area | FreeBSD behavior |
| --- | --- |
| Package manager | `pkg` (quarterly repo by default). `awww` lives only on `latest`; the installer switches the repo automatically if it is missing. |
| AUR | Removed (`ml4w-arch-*`, `ml4w-pacman`, `ml4w-snapshot`, AUR Helper setting). |
| ML4W Settings GUI | Removed (Flutter app, not available on FreeBSD). Settings are edited in `~/.config/ml4w-dotfiles-settings/com.ml4w.dotfiles/settings.json`. |
| Networking | FreeBSD-native: `wpa_supplicant` + `wifimgr` + `ifconfig`/`dhclient`. No NetworkManager / nm-applet. `ml4w-wifi-status` and `ml4w-wifi-toggle` replace the NetworkManager bindings in swaync and Waybar. |
| Init / power | No systemd. `loginctl suspend` (elogind) with `sudo zzz` fallback; `sudo shutdown -r/-p`. |
| Brightness | Base `backlight(8)` wrapper (`~/.config/hypr/scripts/brightness.sh`); needs the `operator` group. Brightness slider in the sidebar uses it too. |
| HiDPI / keyboard backlight | `hypridle.conf` kbd-backlight section is disabled (FreeBSD uses `sysctl dev.acpi_kbd.brightness`). |
| Portals / polkit | `restart-portals.sh` + `polkit-agent.sh` in `autostart.lua`. |
| Clipboard | `wl-clipboard`, `xclip` (not `xsel`). |
| File watching | `fswatch` (kqueue) instead of `inotifywait` (see `gtk-theme-switcher.sh`, `dev/sync.sh`). |
| ccache | `/usr/local/libexec/ccache` in `PATH` (`bashrc/00-init`, `fish/conf.d/00_init.fish`). |
| Shell setup | `ml4w-change-shell` relies on Oh My Posh provided by `post-freebsd.sh` (no curl installer). |

## Networking quick notes

Wi-Fi is configured per device in `/etc/rc.conf`:

```
wlans_iwlwifi0="wlan0"
ifconfig_wlan0="WPA SYNCDHCP"
```

`/etc/wpa_supplicant.conf` manages WPA credentials (a stub is created by the
preflight). Use `wifimgr` or `ml4w-wifi-toggle` from the control center.

## Troubleshooting

- **No backlight**: ensure your user is in the `operator` group
  (`pw groupmod operator -m <user>`) and xbacklight/backlight is not occupied.
- **No brightness on NVIDIA**: brightness for desktop GPUs is uncommon; the
  slider silently reports nothing instead of failing.
- **awww missing**: the installer enables the `latest` repo automatically. To
  force it manually:

  ```sh
  mkdir -p /usr/local/etc/pkg/repos
  echo 'FreeBSD: { url: "pkg+http://pkg.FreeBSD.org/${ABI}/latest" }' > /usr/local/etc/pkg/repos/FreeBSD.conf
  pkg update -f && pkg install -y awww
  ```

- **Wayland session does not start**: verify dbus + elogind are enabled
  (`sysrc dbus_enable=YES`, `sysrc elogind_enable=YES`), reboot, and check
  `~/.local/share/sddm/wayland-session.log` or the console log.