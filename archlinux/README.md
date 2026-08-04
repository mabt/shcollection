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
  GRUB+os-prober, zram, autologin tty2, PAM keyring, ~120 paquets desktop,
  services (dont `pcscd.socket`, requis par la YubiKey en phase 3)
- **archsway-3-user.sh** — au 1er boot, en user : yay + paquets AUR,
  `chezmoi init --apply` (dotfiles → sway, waybar, crontab…), claude-code.
  Prérequis : YubiKey branchée **et fonctionnelle** (clé SSH GitHub pour le
  repo dotfiles privé) — c'est la phase 2 qui active `pcscd.socket`, sans
  lequel la clé PIV reste invisible.

Variables surchargeables par env : `DISK`, `RAW_URL` (tests).

## Reste manuel après la phase 3

bluetoothctl (pairing), comptes nordvpn/insync/nextcloud, openvpn (.conf),
addons Firefox, LUKS+YubiKey.

Puis, **une fois la première synchro Insync terminée**, un second
`chezmoi apply` : le dossier Insync n'existe pas encore pendant la phase 3,
donc le hook `20-system-setup` n'a pas pu créer le symlink `~/claude` ni
reposer les règles d'exclusion. Il le signale au lieu d'échouer.

La crontab n'est plus à réimporter : elle est déployée par chezmoi
(`.config/crontab.txt` + hook `update-crontab.sh`).

## Pièges vérifiés (réinstall du 2026-08-04)

- **`~/claude` doit être un symlink** vers `Insync/…/gdrive/claude`. Si une
  restauration en fait un vrai dossier, deux copies divergent en silence (ici :
  le cron d'alerting écrivait dans la mauvaise). Ne jamais supprimer le dossier
  local : fusionner d'abord (`rsync -a ~/claude/ <Insync>/`), vérifier l'écart
  **dans les deux sens**, puis remplacer par le lien.
- **Les règles d'exclusion Insync sont remises à zéro** à chaque réinstall.
  `*.log` seul ne suffit pas : il faut aussi `*.log.*` pour les rotations
  (`.log.1`, `.log.2.gz`), sinon ~1 Go de logs part sur Drive.
  → `insync ignore-rules add "claude/tmp" "*.log" "*.log.*"`
- **`pcscd.socket` désactivé** = « Échec du chargement de la clé PIV » et
  `ykman list` → « PC/SC not available ». Corrigé en phase 2.
- **Tout ce qui n'est pas dans le dépôt dotfiles est perdu.** En 2026-08-04 :
  4 scripts `~/.local/bin` appelés par waybar (réécrits de zéro, aucune copie
  n'existait). Réflexe : `chezmoi add <chemin>` dès qu'un fichier compte.
- Sous Wayland, `gammastep -O` **ne rend pas la main** (wlr-gamma-control
  réinitialise le gamma à la déconnexion du client) : c'est un démon.

## Cohérence des listes de paquets

Les paquets vivent à deux endroits : les phases 1/2/3 ici, et `packages.txt`
du dépôt dotfiles (régénérable par `pacman -Qqen` / `-Qqem`). Pour voir la
dérive entre les deux :

```sh
./check-packages.sh     # sort en 1 s'il y a un écart
```

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
