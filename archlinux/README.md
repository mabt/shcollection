# archsway

Réinstallation d'un poste Arch Linux (Sway/Wayland, NVIDIA), en 3 phases.

Depuis l'ISO Arch (UEFI, réseau OK) :

```sh
loadkeys fr
bash <(curl -fsSL github.com/mabt/shcollection/raw/main/a.sh)
```

- **archsway-1-base.sh** : efface le NVMe (`nvme format --ses=1`), GPT
  (ESP 512M + root LUKS2/ext4, swap = zram), pacstrap, puis lance la phase 2.
- **archsway-2-chroot.sh** : locale, user, paquets, NVIDIA, initramfs
  `sd-encrypt`, GRUB (+ copie de secours `EFI/BOOT/BOOTX64.EFI`), services.
- **archsway-3-user.sh** : après le reboot, en user. AUR (yay), YubiKey FIDO2
  pour LUKS (`systemd-cryptenroll`), dotfiles (chezmoi).

## Test en VM (vm-test/)

```sh
cd vm-test
python3 -m http.server 8000 --bind 127.0.0.1 --directory .. &
bash run-vm.sh &        # QEMU : NVMe émulé + UEFI (OVMF) + ISO (archlinux.iso)
python3 driver.py       # pilote l'install complète, verdict dans status.txt
```

`check-packages.sh` compare les listes de paquets des phases avec celle des dotfiles.
