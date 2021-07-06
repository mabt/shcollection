#!/bin/bash

rm_if_link(){ [ ! -L "$1" ] || rm "$1"; }

PATH_CURRENT=/home/xUSERX/www/xUSERX/current
PATH_SHARED=/home/xUSERX/www/xUSERX/shared

FILES="/app/etc/config.local.php
/app/etc/env.php
/pub/media
/pub/sitemaps
/var/backups
/var/composer_home
/var/export
/var/importexport
/var/import_history
/var/log
/var/session
/var/.setup_cronjob_status
/var/tmp
/var/.update_cronjob_status
"

for i in $FILES; do
rm_if_link $PATH_CURRENT$i;
#ls $PATH_CURRENT$i;
if [ $? -eq 0 ]; then echo $PATH_CURRENT$i have been deleted.; else echo error; fi
ln -s $PATH_SHARED$i $PATH_CURRENT$i
if [ $? -eq 0 ]; then echo $PATH_CURRENT$i symlink have been created.; else echo error; fi
done
