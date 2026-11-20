#!/bin/bash
# =====================================================================
# archsway-1-base.sh — Phase 1 : depuis le live ISO Arch (en root)
# Partitionne, installe la base, puis lance archsway-2-chroot.sh en chroot.
#
# Usage :
#   loadkeys fr
#   curl -fsSL https://raw.githubusercontent.com/mabt/shcollection/main/archlinux/archsway-1-base.sh -o a.sh
#   bash a.sh          # éditer les variables ci-dessous avant si besoin
# =====================================================================
set -euo pipefail
exec > >(tee /tmp/archsway-phase1.log) 2>&1

# ------------------------- VARIABLES (surchargeables par env) --------
DISK="${DISK:-/dev/nvme0n1}"
RAW_URL="${RAW_URL:-https://raw.githubusercontent.com/mabt/shcollection/main/archlinux}"

# ------------------------- VERIFICATIONS -----------------------------
[[ -d /sys/firmware/efi/efivars ]] || { echo "ERREUR : boot en mode BIOS, UEFI requis"; exit 1; }
[[ -b "$DISK" ]] || { echo "ERREUR : $DISK introuvable"; exit 1; }
ping -c1 -W3 archlinux.org >/dev/null || { echo "ERREUR : pas de réseau (iwctl pour le wifi)"; exit 1; }

echo "=== Disques détectés ==="
lsblk -dno NAME,SIZE,MODEL
# si plusieurs NVMe : l'ordre nvme0/nvme1 n'est pas stable d'un boot à
# l'autre -> exiger un choix explicite et assumé
if [[ -z "${DISK_FORCE:-}" && $(ls -1 /dev/nvme?n1 2>/dev/null | wc -l) -gt 1 ]]; then
    echo "ERREUR : plusieurs NVMe détectés — relancer avec DISK=/dev/nvmeXn1 DISK_FORCE=1"
    exit 1
fi

echo
echo "!!! TOUT LE CONTENU DE $DISK ($(lsblk -dno SIZE,MODEL "$DISK")) VA ETRE EFFACE !!!"
lsblk "$DISK"
read -rp "Taper OUI pour continuer : " confirm
[[ "$confirm" == "OUI" ]] || exit 1

loadkeys fr
timedatectl set-ntp true

# ------------------------- EFFACEMENT DES ANCIENNES DONNEES ----------
# Format NVM "User Data Erase" (--ses=1) : le contrôleur efface tout le
# disque, zones cachées comprises (shred/dd sont inutiles sur un SSD).
# En cas d'échec, on ne continue PAS en silence : le TRIM seul rend les
# données illisibles par un PC normal, mais pas par un labo (lecture des
# puces) tant que le SSD ne les a pas effacées physiquement.
if [[ "$DISK" == /dev/nvme* ]] && nvme format "$DISK" --ses=1 --force; then
    echo "--- $DISK effacé (nvme format --ses=1) ---"
else
    echo "!!! nvme format --ses=1 a échoué : les anciennes données ne sont PAS effacées physiquement"
    read -rp "Taper TRIM pour continuer avec un simple TRIM, autre chose pour arrêter : " r
    [[ "$r" == "TRIM" ]] || exit 1
    blkdiscard -f "$DISK" || true
fi
sleep 2

# ------------------------- PARTITIONNEMENT ---------------------------
# GPT : 1 EFI 512M (= /boot, non chiffrée) + 1 root LUKS2 -> ext4
# (pas de partition swap : zram, en RAM, donc rien ne fuit en clair)
sgdisk --zap-all "$DISK"
sgdisk -n1:0:+512M -t1:ef00 -c1:"EFI" "$DISK"
sgdisk -n2:0:0     -t2:8304 -c2:"root" "$DISK"
partprobe "$DISK"; sleep 2

EFI_PART="${DISK}p1"
ROOT_PART="${DISK}p2"

mkfs.fat -F32 "$EFI_PART"

# ------------------------- CHIFFREMENT LUKS2 -------------------------
# Protège les données en cas de vol. Passphrase = secours ; la YubiKey
# (FIDO2) est enrôlée en phase 3 via systemd-cryptenroll.
echo "--- Passphrase LUKS du disque (à ne pas perdre !) ---"
cryptsetup luksFormat --type luks2 --pbkdf argon2id --batch-mode --verify-passphrase "$ROOT_PART"
cryptsetup open --allow-discards --persistent "$ROOT_PART" cryptroot
mkfs.ext4 -F /dev/mapper/cryptroot

mount /dev/mapper/cryptroot /mnt
mount --mkdir "$EFI_PART" /mnt/boot

# ------------------------- MIROIRS + BASE ----------------------------
pacman -Sy --noconfirm archlinux-keyring reflector
reflector --country France,Germany --age 12 --protocol https \
          --sort rate --save /etc/pacman.d/mirrorlist

pacstrap -K /mnt base base-devel linux linux-firmware amd-ucode \
                 nano sudo cryptsetup networkmanager efibootmgr grub os-prober git

genfstab -U /mnt >> /mnt/etc/fstab

# ------------------------- PHASE 2 (CHROOT) --------------------------
# copie locale si dispo (les 2 scripts côte à côte), sinon curl
if [[ -f "$(dirname "$0")/archsway-2-chroot.sh" ]]; then
    cp "$(dirname "$0")/archsway-2-chroot.sh" /mnt/root/
else
    curl -fsSL "$RAW_URL/archsway-2-chroot.sh" -o /mnt/root/archsway-2-chroot.sh
fi
chmod +x /mnt/root/archsway-2-chroot.sh
ROOT_UUID="$(cryptsetup luksUUID "$ROOT_PART")"
arch-chroot /mnt env ROOT_UUID="$ROOT_UUID" /root/archsway-2-chroot.sh

# ------------------------- FIN ---------------------------------------
rm /mnt/root/archsway-2-chroot.sh
umount -R /mnt
cryptsetup close cryptroot
echo "=== Phase 1+2 terminées. Retirer la clé USB. ==="
read -rp "Entrée pour rebooter..." _
reboot
