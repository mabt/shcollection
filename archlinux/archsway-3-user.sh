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
if ! command -v yay >/dev/null; then
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && makepkg -si --noconfirm)
fi

# = pacman -Qqem du 2026-07-02 (moins yay lui-même)
yay -S --noconfirm --needed \
    anydesk-bin downgrade insync nordvpn-bin raw-thumbnailer \
    redshifter rustdesk-bin simple-mtpfs typora update-grub \
    vlc-bittorrent witr zoiper-bin

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

echo "=== Phase 3 terminée — reste à faire à la main : ==="
cat <<'EOF'
 - reboot (ou Ctrl-D : l'autologin tty2 relance sway via .bash_profile)
 - bluetoothctl : pairing clavier/casque (trust/pair/connect $MAC)
 - nordvpn login / insync / nextcloud : connexion aux comptes
 - openvpn : copier le .conf puis systemctl enable openvpn-client@<nom>
 - firefox : addons + about:config (browser.uidensity=1)
 - disque LUKS sdb1 : brancher la YubiKey, config déverrouillage (yk-unlock-gui)
 - crontab -e : réimporter les crons (bell, alerting, backup-claude-remote-mirror)
EOF
