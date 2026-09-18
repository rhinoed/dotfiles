#!/usr/bin/env bash
# --------------------------------------------------------------
# FreeBSD preflight: kernel modules, rc.conf services, PAM, groups
# --------------------------------------------------------------
# Sourced by setup/setup.sh. Uses $SUDO (set by the installer).
# Idempotent - safe to run multiple times.
# --------------------------------------------------------------

info "Configuring FreeBSD system for Hyprland"

# --------------------------------------------------------------
# GPU kernel modules (kld_list in /etc/rc.conf)
# --------------------------------------------------------------

detect_gpu_kld() {
    local vendor
    local kld=""
    if $SUDO pciconf -lv 2>/dev/null | grep -q 'class *= *0x03'; then
        vendor="$($SUDO pciconf -lv 2>/dev/null | awk '/class *= *0x03/{f=1} f&&/vendor *= *0x/{print $3; exit}')"
        case "$vendor" in
            *1002) kld="amdgpu" ;;
            *8086) kld="i915kms" ;;
            *10de) kld="nvidia" ;;
        esac
    fi
    if [ -z "$kld" ]; then
        warn "No supported GPU found via pciconf. Add the matching drm module to kld_list manually."
        return
    fi
    if printf '%s\n' "$(/usr/sbin/sysrc -n kld_list 2>/dev/null)" | grep -qw "$kld"; then
        info "kld_list already contains $kld"
    else
        info "Adding $kld to kld_list in /etc/rc.conf"
        $SUDO /usr/sbin/sysrc "kld_list+=\" $kld\""
    fi
}

detect_gpu_kld

# --------------------------------------------------------------
# rc.conf services
# --------------------------------------------------------------

$SUDO /usr/sbin/sysrc dbus_enable="YES"
$SUDO /usr/sbin/sysrc elogind_enable="YES"

# --------------------------------------------------------------
# Wifi (wpa_supplicant + wifimgr)
# --------------------------------------------------------------
# The wlan interface must still be configured per device in /etc/rc.conf, e.g:
#   wlans_iwlwifi0="wlan0"
#   ifconfig_wlan0="WPA SYNCDHCP"
$SUDO /usr/sbin/sysrc wpa_supplicant_enable="YES"

if [ ! -f /etc/wpa_supplicant.conf ]; then
    info "Creating stub /etc/wpa_supplicant.conf"
    $SUDO sh -c "printf 'ctrl_interface=/var/run/wpa_supplicant\nnetwork={\n}\n' > /etc/wpa_supplicant.conf"
    $SUDO chmod 600 /etc/wpa_supplicant.conf
fi

# Optionally enable SDDM as display manager (comment out to disable)
# $SUDO /usr/sbin/sysrc sddm_enable="YES"

# --------------------------------------------------------------
# Login shells (needed by ml4w-change-shell / chsh)
# --------------------------------------------------------------
for shell in /usr/local/bin/bash /usr/local/bin/zsh /usr/local/bin/fish; do
    if [ -x "$shell" ] && ! grep -qx "$shell" /etc/shells 2>/dev/null; then
        info "Registering $shell in /etc/shells"
        echo "$shell" | $SUDO tee -a /etc/shells >/dev/null
    fi
done

# --------------------------------------------------------------
# PAM - elogind session handling
# --------------------------------------------------------------

apply_pam() {
    local file="$1"
    if [ ! -f "$file" ]; then
        warn "PAM file not found, skipping: $file"
        return
    fi
    if grep -q 'pam_elogind' "$file" 2>/dev/null; then
        info "pam_elogind already configured in $file"
    else
        info "Adding pam_elogind to $file"
        $SUDO sh -c "printf 'session\toptional\tpam_elogind.so\n' >> ${file}"
    fi
}

apply_pam /etc/pam.d/system-session
if [ -f /etc/pam.d/login ]; then
    apply_pam /etc/pam.d/login
fi

# --------------------------------------------------------------
# Groups
# --------------------------------------------------------------

CURRENT_USER="${SUDO_USER:-$LOGNAME}"
if [ -n "$CURRENT_USER" ] && [ "$CURRENT_USER" != "root" ]; then
    info "Adding $CURRENT_USER to video, operator and wheel groups"
    $SUDO pw groupmod video -m "$CURRENT_USER" || true
    $SUDO pw groupmod operator -m "$CURRENT_USER" || true
    $SUDO pw groupmod wheel -m "$CURRENT_USER" || true
else
    warn "Could not determine the invoking user. Add your user to the 'video' and 'operator' groups manually: pw groupmod video -m \$USER"
fi

info "Preflight done. Please reboot after the installation completes."