#!/bin/bash
# =====================================================================
# archsway-2-chroot.sh — Phase 2 : dans le chroot (lancé auto par phase 1)
# Système, user, NVIDIA, GRUB, services, zram, paquets desktop.
# =====================================================================
set -euo pipefail
exec > >(tee /var/log/archsway-phase2.log) 2>&1

# ------------------------- VARIABLES ---------------------------------
HOSTNAME="desktop"
USERNAME="mabe"
TIMEZONE="Europe/Paris"
LOCALE="en_US.UTF-8"        # fr_FR.UTF-8 générée en plus
KEYMAP="fr"

# ------------------------- LOCALE / TIME / HOSTNAME ------------------
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
hwclock --systohc

sed -i 's/^#en_US.UTF-8/en_US.UTF-8/; s/^#fr_FR.UTF-8/fr_FR.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain  $HOSTNAME
EOF

# ------------------------- ROOT + USER -------------------------------
echo "--- Mot de passe root ---"
passwd
useradd --create-home --groups wheel,video,audio,input,storage "$USERNAME"
echo "--- Mot de passe $USERNAME ---"
passwd "$USERNAME"
echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel

# ------------------------- PACMAN.CONF -------------------------------
sed -i 's/^#\?ParallelDownloads.*/ParallelDownloads = 10/; s/^#Color$/Color/' /etc/pacman.conf
# multilib volontairement désactivé

# ------------------------- PAQUETS DESKTOP ---------------------------
# = pacman -Qqen du 2026-08-03, moins la base (phase 1), moins
#   autorandr (X11, inutile sous sway) et dhcpcd (doublon de NM).
#   NB: swaylock remplacé par swaylock-effects (AUR) -> phase 3.
#   gammastep (night-light, Mod+m), cliphist (presse-papier, Mod+p) et
#   wireplumber (volume via wpctl) requis par la config sway/waybar.
#   less : $PAGER par défaut, sinon `glow -p` referme sa fenêtre aussitôt.
#   moreutils : sponge, utilisé dans les one-liners de maintenance.
pacman -Syu --noconfirm --needed \
  sway swaybg swayidle waybar wofi bemenu mako foot gammastep \
  grim slurp satty flameshot wl-clipboard cliphist xdg-desktop-portal-wlr snixembed \
  xorg-xwayland xclip polkit-gnome ly \
  nvidia-open nvidia-settings libva-nvidia-driver libva-utils \
  pipewire-alsa pipewire-pulse wireplumber alsa-utils pavucontrol pasystray \
  bluez bluez-utils blueman headsetcontrol piper \
  network-manager-applet openvpn wireguard-tools openssh sshfs rsync \
  nmap mtr whois traceroute inetutils net-tools dog wget minidlna \
  firefox chromium thunderbird terminator tmux \
  keepassxc discord telegram-desktop nextcloud-client filezilla \
  featherpad libreoffice-fresh gimp kdenlive mpv vlc vlc-plugins-all zvbi \
  gthumb imagemagick ffmpegthumbnailer transmission-qt copyq yad wine \
  nemo nemo-fileroller nemo-image-converter udiskie \
  7zip unzip unrar unrar-free unp dosfstools \
  chezmoi github-cli emacs-nox npm php php-sqlite python-pip \
  python-lz4 python-maxminddb jq glow tldr fastfetch \
  htop iotop ncdu geoip-database-extra percona-server-clients \
  qemu-full guestfs-tools tigervnc ttyd \
  bash-completion xdg-user-dirs less moreutils \
  gnome-keyring cronie smartmontools nvme-cli zram-generator \
  yubico-piv-tool yubikey-manager \
  noto-fonts noto-fonts-emoji ttf-dejavu

# ------------------------- NVIDIA ------------------------------------
# Requis pour suspend/resume propre (VRAM préservée)
cat > /etc/modprobe.d/nvidia-power-management.conf <<EOF
options nvidia NVreg_PreserveVideoMemoryAllocations=1 NVreg_TemporaryFilePath=/var/tmp
EOF

mkinitcpio -P

# ------------------------- BOOTLOADER --------------------------------
grub-install --target=x86_64-efi --efi-directory=/boot \
             --bootloader-id=grub --recheck
sed -i 's/^#\?GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# ------------------------- ZRAM (remplace swapfile) ------------------
cat > /etc/systemd/zram-generator.conf <<EOF
[zram0]
zram-size = min(ram / 2, 16384)
compression-algorithm = zstd
EOF

# ------------------------- AUTOLOGIN TTY2 ----------------------------
# tty1 = login manuel, tty2 = autologin ; .bash_profile (chezmoi)
# lance sway-start sur les deux
# (getty@ et non autovt@ : systemd refuse d'enabler l'alias autovt@)
mkdir -p /etc/systemd/system/getty@tty2.service.d
cat > /etc/systemd/system/getty@tty2.service.d/autologin.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -f -- \\\\u' --noclear --autologin $USERNAME %I \$TERM
EOF

# ------------------------- PAM GNOME-KEYRING -------------------------
grep -q pam_gnome_keyring /etc/pam.d/login || {
  sed -i '/^auth/a auth       optional     pam_gnome_keyring.so' /etc/pam.d/login
  echo "session    optional     pam_gnome_keyring.so auto_start" >> /etc/pam.d/login
}

# ------------------------- SERVICES ----------------------------------
# pcscd.socket : indispensable à la YubiKey PIV. Sans lui, libykcs11 ne voit
# pas la clé ("Échec du chargement de la clé PIV", `ykman list` → "PC/SC not
# available") — donc la phase 3 ne peut même pas cloner le repo dotfiles privé.
# Les paquets pcsclite et ccid arrivent en dépendance de yubikey-manager.
systemctl enable NetworkManager bluetooth cronie systemd-timesyncd fstrim.timer \
                 nvidia-suspend nvidia-resume nvidia-hibernate \
                 pcscd.socket \
                 getty@tty2

echo "=== Phase 2 (chroot) terminée ==="
