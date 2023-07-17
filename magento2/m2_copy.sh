#!/bin/bash                                                                                                                                                                                                                                                                                                                                                                                                                       

PATH_DEV=/path/dev
PATH_PROD=/path/prod
DB_PROD=prod
DB_DEV=dev
DB_USER=root
DB_PASS=password
OWNER=ab00000-0000
BASE_URL=https://domaine.com/
ENV_PHP=/path/scripts/env.php
ES_PREFIX=dev.m2

read -p "Are you sure to erase $PATH_DEV ? " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

rm -rf $PATH_DEV && mkdir $PATH_DEV

mysqldump --single-transaction $DB_PROD > $PATH_DEV/export-$(date +"%m_%d_%Y").sql

mysql -e "drop database `${DB_DEV}`"
mysql -e "create database `${DB_DEV}`"

mysql $DB_DEV < $PATH_DEV/export-$(date +"%m_%d_%Y").sql

rsync -a --exclude 'var/session/*' --exclude 'var/cache/*' --exclude 'media/catalog/product/cache/*' $PATH_PROD $PATH_DEV

mysql -e "UPDATE core_config_data SET value = '${BASE_URL}' WHERE path = 'web/%secure/base_url';"
mysql -e "UPDATE core_config_data SET value = '${ES_PREFIX}' WHERE path = 'catalog/search/elasticsearch7_index_prefix';" 


cp $ENV_PHP $PATH_DEV/app/etc/env.php
cd $PATH_DEV && php bin/magento cache:c && php bin/magento cache:f
chown -R $OWNER. $PATH_DEV

# misc
#sed 's/\sDEFINER=`[^`]*`@`[^`]*`//g' -i $PATH_DEV/export-$(date +"%m_%d_%Y").sql
#mysql -e "UPDATE core_config_data SET value = 1 WHERE path = 'system/smtp/disable'"
#mysql -e "UPDATE core_config_data set value = '0' where path = 'admin/url/use_custom';"
#echo -e 'User-agent:* \nDisallow: /' > $PATH_DEV/robots.txt
