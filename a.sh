#!/bin/bash
# Bootstrap archsway — usage depuis l'ISO Arch :
#   bash <(curl -fsSL github.com/mabt/shcollection/raw/main/a.sh)
curl -fsSL https://raw.githubusercontent.com/mabt/shcollection/main/archlinux/archsway-1-base.sh -o /tmp/archsway-1.sh
exec bash /tmp/archsway-1.sh "$@"
