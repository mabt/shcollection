#!/bin/bash
# =====================================================================
# check-packages.sh — détecte la dérive entre les deux sources de vérité
# des paquets :
#   1. la chaîne archsway (phases 1/2/3 : pacstrap, pacman, yay)
#   2. packages.txt du dépôt dotfiles (= pacman -Qqen + -Qqem régénérés)
#
# Ne modifie rien : affiche les écarts et sort en 1 s'il y en a.
#   PACKAGES_TXT=/autre/chemin ./check-packages.sh   (surcharge)
# =====================================================================
set -uo pipefail

cd "$(dirname "$0")"

PACKAGES_TXT="${PACKAGES_TXT:-$(chezmoi source-path 2>/dev/null)/packages.txt}"
[ -f "$PACKAGES_TXT" ] || { echo "packages.txt introuvable : $PACKAGES_TXT" >&2; exit 2; }

# Extrait les paquets d'une commande multi-lignes (continuations par \)
extract() {
    local file=$1 start=$2 strip=$3
    awk -v start="$start" -v strip="$strip" '
        index($0, start) == 1 { inb = 1; sub(strip, "") }
        inb {
            line = $0
            sub(/#.*/, "", line)
            gsub(/\\/, " ", line)
            print line
            if ($0 !~ /\\[[:space:]]*$/) exit
        }
    ' "$file" | tr -s '[:space:]' '\n' | grep -v '^$'
}

archsway=$(
    {
        extract archsway-1-base.sh  "pacstrap"   "^pacstrap -K /mnt"
        extract archsway-2-chroot.sh "pacman -Syu" "^pacman -Syu --noconfirm --needed"
        extract archsway-3-user.sh   "yay -S"      "^yay -S --noconfirm --needed"
    } | sort -u
)

# yay est amorcé par makepkg en phase 3 (volontairement hors des listes) et les
# paquets -debug sont des artefacts de compilation AUR : ni l'un ni l'autre
# n'est une dérive.
filtre() { grep -vx 'yay' | grep -v -- '-debug$'; }

archsway=$(filtre <<< "$archsway")
inventaire=$(sed 's/#.*//' "$PACKAGES_TXT" | tr -s '[:space:]' '\n' | grep -v '^$' | filtre | sort -u)

echo "archsway : $(wc -l <<< "$archsway") paquets   |   packages.txt : $(wc -l <<< "$inventaire") paquets"
ecarts=0

manquants=$(comm -13 <(echo "$archsway") <(echo "$inventaire"))
if [ -n "$manquants" ]; then
    ecarts=1
    echo
    echo "── Dans packages.txt mais PAS installés par archsway ─────────────"
    echo "   (installés après coup : ils seront perdus à la prochaine install"
    echo "    si tu ne les ajoutes pas à la phase 2 ou 3)"
    sed 's/^/   + /' <<< "$manquants"
fi

obsoletes=$(comm -23 <(echo "$archsway") <(echo "$inventaire"))
if [ -n "$obsoletes" ]; then
    ecarts=1
    echo
    echo "── Installés par archsway mais absents de packages.txt ───────────"
    echo "   (désinstallés depuis, ou packages.txt à régénérer :"
    echo "    pacman -Qqen / pacman -Qqem)"
    sed 's/^/   - /' <<< "$obsoletes"
fi

if [ "$ecarts" -eq 0 ]; then
    echo
    echo "✓ les deux listes sont alignées"
fi
exit "$ecarts"
