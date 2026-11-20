#!/bin/bash
# =====================================================================
# archsway-3-user.sh — Phase 3 : après le 1er reboot, connecté en mabe
# AUR (yay), dotfiles (chezmoi), touches finales.
#
# Prérequis : clé SSH GitHub dispo (YubiKey branchée) pour le repo
# dotfiles privé — sinon décommenter la variante https plus bas.
# =====================================================================
set -euo pipefail
exec > >(tee /tmp/archsway-phase3.log) 2>&1

[[ $EUID -ne 0 ]] || { echo "ERREUR : lancer en user, pas en root"; exit 1; }
ping -c1 -W3 archlinux.org >/dev/null || { echo "ERREUR : pas de réseau"; exit 1; }

# ------------------------- YAY + AUR ---------------------------------
# pas de paquets *-debug pour l'AUR
mkdir -p ~/.config/pacman
grep -qs '!debug' ~/.config/pacman/makepkg.conf || echo 'OPTIONS+=(!debug)' >> ~/.config/pacman/makepkg.conf

if ! command -v yay >/dev/null; then
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && makepkg -si --noconfirm)
fi

# = pacman -Qqem du 2026-08-04 (moins yay lui-même, amorcé au-dessus)
# swaylock-effects fournit le binaire swaylock (remplace celui du dépôt, phase 2)
yay -S --noconfirm --needed \
    anydesk-bin downgrade insync nordvpn-bin raw-thumbnailer \
    redshifter rustdesk-bin simple-mtpfs swaylock-effects typora update-grub \
    witr zoiper-bin \
    netbird-bin jellyfin-desktop lmstudio-bin scarlett2 scarlett2-firmware \
    wine-nvidia-libs-bin

# ------------------------- LUKS : YUBIKEY FIDO2 ----------------------
# Ajoute la YubiKey comme 2e moyen de déverrouiller le disque (la
# passphrase reste valable en secours). Demande la passphrase + un toucher.
LUKS_DEV="$(sudo cryptsetup status cryptroot | awk '/device:/{print $2}')"
[[ -b "$LUKS_DEV" ]] || { echo "ERREUR : cryptroot introuvable"; exit 1; }
if sudo systemd-cryptenroll "$LUKS_DEV" | grep -c fido2 >/dev/null; then
    echo "YubiKey FIDO2 déjà enrôlée sur $LUKS_DEV"
else
    echo "Prérequis : PIN FIDO2 défini sur la YubiKey (ykman fido info / ykman fido access change-pin)."
    echo "Au boot : PIN + toucher ; sans clé, la passphrase est demandée."
    read -rp "Enrôler la YubiKey (FIDO2) pour déverrouiller le disque ? [o/N] " r
    [[ "$r" == [oO] ]] && { sudo systemd-cryptenroll --fido2-device=auto "$LUKS_DEV" \
        || echo "ATTENTION : enrôlement FIDO2 échoué, à refaire à la main"; }
fi

# ------------------------- DOTFILES (chezmoi) ------------------------
# Couvre : .bash_profile (lance sway sur tty1/tty2), sway, waybar,
# mako, rofi, terminator, gtk, autostart, ~/.local/bin (sway-start...)
chezmoi init --apply git@github.com:mabt/dotfiles.git
# variante sans clé SSH (repo public/https + token) :
# chezmoi init --apply https://github.com/mabt/dotfiles.git

# ------------------------- XDG DIRS EN ANGLAIS -----------------------
LC_ALL=C xdg-user-dirs-update --force

# ------------------------- CLAUDE CODE -------------------------------
sudo npm install -g @anthropic-ai/claude-code

echo "=== Phase 3 terminée ==="
echo "Suite (à la main) : ~/.local/share/chezmoi/reinstall/TODO-apres-install.md"
