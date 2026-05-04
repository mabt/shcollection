#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

run() {
    local label="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} ${label}"
    else
        echo -e "  ${RED}✗${NC} ${label}"
    fi
}

echo "Resetting caches..."
echo

for sock in /run/php/*.sock; do
    [ -e "$sock" ] || continue
    name=$(basename "$sock" .sock)
    run "OPcache reset ($name)" /usr/bin/php /usr/local/bin/cachetool opcache:reset -t /tmp/ --fcgi="$sock"
done

php_ok=true
for fpm in /usr/sbin/php-fpm*; do
    [ -x "$fpm" ] || continue
    name=$(basename "$fpm")
    if ! run "$name configtest" "$fpm" -t; then
        php_ok=false
    fi
done

if $php_ok; then
    run "PHP-FPM restart"        /usr/bin/systemctl restart php*-fpm
else
    echo -e "  ${RED}✗${NC} PHP-FPM restart skipped (configtest failed)"
fi
run "Redis restart"              /usr/bin/systemctl restart redis-*.service
run "Varnish restart"            /usr/bin/systemctl restart varnish-*.service

echo
echo "Done."
