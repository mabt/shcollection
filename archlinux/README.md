# archsway — réinstallation Arch Linux + Sway automatisée

3 scripts pour réinstaller le desktop (Sway/Wayland, NVIDIA, dotfiles chezmoi).
Testés en VM QEMU (NVMe + UEFI) : install complète en ~3 min sur fibre.

## Utilisation (depuis l'ISO Arch, en root)

```sh
loadkeys fr
curl -fsSL https://raw.githubusercontent.com/mabt/shcollection/main/archlinux/archsway-1-base.sh -o a.sh
nano a.sh        # vérifier DISK (défaut /dev/nvme0n1)
bash a.sh        # confirmation OUI + 2×2 mots de passe (root, mabe)
```

- **archsway-1-base.sh** — partitionne (GPT : EFI 512M + root ext4, pas de
  swap → zram), pacstrap, puis enchaîne automatiquement sur :
- **archsway-2-chroot.sh** — locale/tz/user, NVIDIA (nvidia-open + suspend),
  GRUB+os-prober, zram, autologin tty2, PAM keyring, ~120 paquets desktop
- **archsway-3-user.sh** — au 1er boot, en user : yay + paquets AUR,
  `chezmoi init --apply` (dotfiles → sway, waybar, crontab…), claude-code.
  Prérequis : YubiKey branchée (clé SSH GitHub pour le repo dotfiles).

Variables surchargeables par env : `DISK`, `RAW_URL` (tests).

## Reste manuel après la phase 3

bluetoothctl (pairing), comptes nordvpn/insync/nextcloud, openvpn (.conf),
addons Firefox, LUKS+YubiKey, restaurer `~/claude/tmp/alerting/` (cron).

## Test en VM (vm-test/)

```sh
cd vm-test
python3 -m http.server 8000 --directory .. &   # sert les scripts en local
bash run-vm.sh &                               # VM QEMU : NVMe + OVMF + ISO
python3 driver.py                              # pilote tout, verdict dans status.txt
```

`ARCHSWAY_URL=https://raw.githubusercontent.com/mabt/shcollection/main/archlinux python3 driver.py`
teste le vrai flux GitHub (sans serveur local). L'ISO `archlinux.iso` est à
télécharger dans `vm-test/` au préalable.
