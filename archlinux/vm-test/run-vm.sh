#!/bin/bash
# Lance la VM de test archi3 : NVMe émulé + UEFI (OVMF) + boot sur l'ISO.
# Monitor QEMU sur tcp:5556, console série sur tcp:5555, VNC :1 pour debug.
set -euo pipefail
cd "$(dirname "$0")"

qemu-img create -f qcow2 disk.qcow2 40G
cp /usr/share/edk2/x64/OVMF_VARS.4m.fd vars.fd

exec qemu-system-x86_64 \
  -enable-kvm -m 6144 -smp 6 -cpu host \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.4m.fd \
  -drive if=pflash,format=raw,file=vars.fd \
  -drive file=disk.qcow2,if=none,id=nvm,format=qcow2,discard=unmap \
  -device nvme,serial=testnvme,drive=nvm \
  -cdrom archlinux.iso -boot once=d \
  -netdev user,id=n1 -device virtio-net-pci,netdev=n1 \
  -serial tcp:127.0.0.1:5555,server=on,wait=off \
  -monitor tcp:127.0.0.1:5556,server=on,wait=off \
  -display none -vga std -vnc 127.0.0.1:1
