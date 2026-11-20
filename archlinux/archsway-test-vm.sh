#!/usr/bin/env bash
#
# archsway-test-vm.sh — VM QEMU/UEFI jetable pour tester l'install archsway.
#
# Émule un disque NVMe (le guest voit /dev/nvme0n1) + firmware UEFI (OVMF),
# donc archsway-1/2/3 tournent SANS MODIF (leur DISK par défaut colle).
#
#   ./archsway-test-vm.sh setup             # paquets nécessaires (1 fois)
#   ./archsway-test-vm.sh iso               # (re)télécharge l'ISO Arch
#   ./archsway-test-vm.sh create test1      # crée disque vierge + vars UEFI
#   ./archsway-test-vm.sh install test1     # boote l'ISO -> phases 1+2
#   ./archsway-test-vm.sh start test1       # boote le disque -> système / phase 3
#   ./archsway-test-vm.sh ssh test1         # SSH (si sshd activé dans le guest)
#   ./archsway-test-vm.sh list              # état des VM
#   ./archsway-test-vm.sh stop test1        # éteint la VM
#   ./archsway-test-vm.sh destroy test1     # supprime la VM et son disque
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Réglages (surchargeables par env)
# ---------------------------------------------------------------------------
ISO_URL="${ISO_URL:-https://geo.mirror.pkgbuild.com/iso/latest/archlinux-x86_64.iso}"
ROOT="${ARCHVM_ROOT:-$HOME/archsway-test}"   # où tout est stocké
ISO_DIR="$ROOT/iso"
VM_DIR="$ROOT/vms"
ISO="$ISO_DIR/archlinux-x86_64.iso"

VM_RAM="${VM_RAM:-4096}"                # Mo de RAM par VM
VM_CPUS="${VM_CPUS:-4}"                 # vCPU par VM
VM_DISK_SIZE="${VM_DISK_SIZE:-40G}"    # taille du disque NVMe émulé (thin)
SSH_PORT_BASE=2222                     # 2222 -> VM1, 2223 -> VM2, ...

# Commandes exactes à taper dans le guest (affichées par 'install')
BOOTSTRAP_URL="https://raw.githubusercontent.com/mabt/shcollection/main/archlinux/archsway-1-base.sh"

# ---------------------------------------------------------------------------
# Utilitaires
# ---------------------------------------------------------------------------
msg()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m/!\\\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mERREUR:\033[0m %s\n' "$*" >&2; exit 1; }

need_bin() { command -v "$1" >/dev/null 2>&1 || die "'$1' manquant — lance d'abord : $0 setup"; }

find_ovmf() {
  # renvoie 2 lignes : chemin CODE puis chemin VARS (modèle, en lecture seule)
  local code='' vars=''
  for c in /usr/share/edk2/x64/OVMF_CODE.4m.fd \
           /usr/share/edk2-ovmf/x64/OVMF_CODE.fd \
           /usr/share/OVMF/OVMF_CODE.fd; do
    [ -f "$c" ] && { code="$c"; break; }
  done
  for v in /usr/share/edk2/x64/OVMF_VARS.4m.fd \
           /usr/share/edk2-ovmf/x64/OVMF_VARS.fd \
           /usr/share/OVMF/OVMF_VARS.fd; do
    [ -f "$v" ] && { vars="$v"; break; }
  done
  [ -n "$code" ] && [ -n "$vars" ] || die "OVMF introuvable (edk2-ovmf) — lance : $0 setup"
  printf '%s\n%s\n' "$code" "$vars"
}

vm_port() {
  local name="$1" pf="$VM_DIR/$name.port"
  [ -f "$pf" ] && { cat "$pf"; return; }
  local p=$SSH_PORT_BASE
  while grep -rqx "$p" "$VM_DIR"/*.port 2>/dev/null; do p=$((p+1)); done
  echo "$p" | tee "$pf"
}

# process QEMU de cette VM. On EXIGE le binaire qemu-system-x86_64 dans le
# match, sinon pgrep -f attraperait n'importe quelle commande citant le chemin
# du disque (y compris ce script lui-même) -> faux positif / auto-kill.
vm_pids() { pgrep -f "qemu-system-x86_64 .*/vms/$1\.qcow2" 2>/dev/null || true; }
is_running() { [ -n "$(vm_pids "$1")" ]; }

require_vm() {
  [ -f "$VM_DIR/$1.qcow2" ] || die "VM '$1' inconnue (crée-la avec : $0 create $1)."
}

# lance QEMU en arrière-plan. $1=nom  $2=extra args (cdrom + no-reboot pour l'install)
run_qemu() {
  local name="$1"; shift
  need_bin qemu-system-x86_64
  local disk="$VM_DIR/$name.qcow2"
  local vmvars="$VM_DIR/$name.OVMF_VARS.fd"
  local port; port="$(vm_port "$name")"
  local log="$VM_DIR/$name.log"
  local code; code="$(find_ovmf | sed -n 1p)"

  # shellcheck disable=SC2086
  setsid qemu-system-x86_64 \
    -name "$name" \
    -machine q35 -cpu host -enable-kvm \
    -smp "$VM_CPUS" -m "$VM_RAM" \
    -drive if=pflash,format=raw,unit=0,readonly=on,file="$code" \
    -drive if=pflash,format=raw,unit=1,file="$vmvars" \
    -drive file="$disk",if=none,id=nvm,format=qcow2 \
    -device nvme,serial="nvme-$name",drive=nvm \
    -device virtio-net-pci,netdev=n0 \
    -netdev user,id=n0,hostfwd=tcp::"$port"-:22 \
    -vga virtio -display gtk \
    "$@" \
    >"$log" 2>&1 &
  echo $! > "$VM_DIR/$name.pid"
  disown || true
  sleep 1
  is_running "$name" || die "QEMU n'a pas démarré — regarde $log"
}

# ---------------------------------------------------------------------------
# setup
# ---------------------------------------------------------------------------
cmd_setup() {
  msg "Installation des paquets (qemu-full, edk2-ovmf, wget, openssh)..."
  sudo pacman -S --needed --noconfirm qemu-full edk2-ovmf wget openssh
  if ! id -nG "$USER" | grep -qw kvm; then
    msg "Ajout de $USER au groupe kvm (déconnecte/reconnecte-toi ensuite)."
    sudo usermod -aG kvm "$USER"
  fi
  msg "Setup OK. Suite : $0 iso  puis  $0 create test1"
}

# ---------------------------------------------------------------------------
# iso : télécharge l'ISO Arch (latest)
# ---------------------------------------------------------------------------
cmd_iso() {
  need_bin wget
  mkdir -p "$ISO_DIR"
  msg "Téléchargement de l'ISO Arch (latest, ~1,2 Go)..."
  wget -c -O "$ISO" "$ISO_URL"
  msg "ISO prête : $ISO"
}
ensure_iso() { [ -f "$ISO" ] || cmd_iso; }

# ---------------------------------------------------------------------------
# create : disque NVMe vierge + copie inscriptible des vars UEFI
# ---------------------------------------------------------------------------
cmd_create() {
  local name="${1:?usage: $0 create <nom>}"
  need_bin qemu-img
  mkdir -p "$VM_DIR"
  local disk="$VM_DIR/$name.qcow2"
  [ -f "$disk" ] && die "La VM '$name' existe déjà (start / install / destroy)."

  local vars; vars="$(find_ovmf | sed -n 2p)"
  msg "Création du disque NVMe vierge ($VM_DISK_SIZE, thin) pour '$name'..."
  qemu-img create -f qcow2 "$disk" "$VM_DISK_SIZE" >/dev/null
  cp "$vars" "$VM_DIR/$name.OVMF_VARS.fd"        # vars UEFI propres à la VM
  vm_port "$name" >/dev/null
  msg "VM '$name' prête. Lance l'install : $0 install $name"
}

# ---------------------------------------------------------------------------
# install : boote l'ISO (disque vierge -> UEFI tombe sur le CD), phases 1+2.
#           -no-reboot : le 'reboot' final de la phase 1 fait quitter QEMU.
# ---------------------------------------------------------------------------
cmd_install() {
  local name="${1:?usage: $0 install <nom>}"
  require_vm "$name"
  is_running "$name" && die "'$name' tourne déjà (stop d'abord)."
  ensure_iso
  msg "Boot de l'ISO pour '$name' (fenêtre graphique)..."
  run_qemu "$name" -cdrom "$ISO" -boot menu=on -no-reboot
  cat <<EOF

  ── Dans la fenêtre de la VM (console live Arch), tape : ────────────────
      loadkeys fr
      curl -fsSL $BOOTSTRAP_URL -o a.sh
      bash a.sh
  ───────────────────────────────────────────────────────────────────────
  DISK par défaut = /dev/nvme0n1 (le NVMe émulé) : rien à surcharger.
  À la fin (phases 1+2), la VM s'éteint toute seule (-no-reboot).
  Ensuite :  $0 start $name   (boot du système installé, pour la phase 3)
EOF
}

# ---------------------------------------------------------------------------
# start : boote le disque installé (pas de CD -> UEFI trouve GRUB)
# ---------------------------------------------------------------------------
cmd_start() {
  local name="${1:?usage: $0 start <nom>}"
  require_vm "$name"
  is_running "$name" && { warn "'$name' tourne déjà."; return 0; }
  local port; port="$(vm_port "$name")"
  msg "Démarrage de '$name' (disque installé, SSH sur le port $port)..."
  run_qemu "$name"
  msg "Fenêtre ouverte. Pour la phase 3, dans un terminal du guest :"
  cat <<'EOF'
      curl -fsSL https://raw.githubusercontent.com/mabt/shcollection/main/archlinux/archsway-3-user.sh -o u.sh
      bash u.sh
  NB phase 3 : le dotfiles chezmoi se fait par SSH GitHub (YubiKey). Sans
  passthrough USB de la clé dans la VM, utiliser la variante https commentée
  dans archsway-3-user.sh (ligne 'chezmoi init --apply https://...').
EOF
}

# ---------------------------------------------------------------------------
# ssh / stop / list / destroy
# ---------------------------------------------------------------------------
cmd_ssh() {
  local name="${1:?usage: $0 ssh <nom>}"
  local port; port="$(vm_port "$name")"
  msg "SSH vers '$name' (mabe@localhost:$port) — nécessite sshd activé dans le guest..."
  exec ssh -p "$port" \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    "mabe@localhost"
}

cmd_stop() {
  local name="${1:?usage: $0 stop <nom>}"
  local pids; pids="$(vm_pids "$name")"
  if [ -n "$pids" ]; then
    # shellcheck disable=SC2086
    kill $pids 2>/dev/null || true
    for _ in 1 2 3 4 5; do sleep 1; pids="$(vm_pids "$name")"; [ -z "$pids" ] && break; done
    # shellcheck disable=SC2086
    [ -n "$pids" ] && kill -9 $pids 2>/dev/null || true
    msg "'$name' éteinte."
  else
    warn "'$name' n'est pas en cours d'exécution."
  fi
  rm -f "$VM_DIR/$name.pid"
}

cmd_list() {
  printf '%-16s %-10s %-8s\n' "NOM" "ÉTAT" "PORT-SSH"
  shopt -s nullglob
  for d in "$VM_DIR"/*.qcow2; do
    local name; name="$(basename "$d" .qcow2)"
    local state=arrêtée; is_running "$name" && state=en_cours
    printf '%-16s %-10s %-8s\n' "$name" "$state" "$(cat "$VM_DIR/$name.port" 2>/dev/null || echo -)"
  done
}

cmd_destroy() {
  local name="${1:?usage: $0 destroy <nom>}"
  cmd_stop "$name" 2>/dev/null || true
  rm -f "$VM_DIR/$name".{qcow2,pid,port,log} "$VM_DIR/$name.OVMF_VARS.fd"
  msg "VM '$name' supprimée."
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
case "${1:-}" in
  setup)   cmd_setup ;;
  iso)     cmd_iso ;;
  create)  shift; cmd_create  "$@" ;;
  install) shift; cmd_install "$@" ;;
  start)   shift; cmd_start   "$@" ;;
  stop)    shift; cmd_stop    "$@" ;;
  ssh)     shift; cmd_ssh     "$@" ;;
  list)    cmd_list ;;
  destroy) shift; cmd_destroy "$@" ;;
  *) cat <<EOF
Usage: $0 <commande> [nom]

  setup            Installe qemu-full, edk2-ovmf, wget, openssh (1 fois)
  iso              (Re)télécharge l'ISO Arch (latest)
  create <nom>     Crée un disque NVMe vierge + vars UEFI
  install <nom>    Boote l'ISO -> phases 1+2 (fenêtre graphique)
  start  <nom>     Boote le disque installé -> système (phase 3)
  ssh    <nom>     SSH dans le guest (si sshd activé)
  stop   <nom>     Éteint la VM
  list             Liste les VM et leur état
  destroy <nom>    Supprime la VM et son disque

Env: VM_RAM (Mo, ${VM_RAM}) · VM_CPUS (${VM_CPUS}) · VM_DISK_SIZE (${VM_DISK_SIZE})
     ARCHVM_ROOT (${ROOT}) · ISO_URL
EOF
     ;;
esac
