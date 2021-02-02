#!/usr/bin/env bash

for i in `cat $1` ; do

path=`echo "$i"|cut -d, -f1`
dbhost=`echo "$i"|cut -d, -f2`
dbname=`echo "$i"|cut -d, -f3`
dbuser=`echo "$i"|cut -d, -f4`
dbpass=`echo "$i"|cut -d, -f5`
base_url=`echo "$i"|cut -d, -f6`
admin_firstname=`echo "$i"|cut -d, -f7`
admin_lastname=`echo "$i"|cut -d, -f8`
admin_email=`echo "$i"|cut -d, -f9`
admin_username=`echo "$i"|cut -d, -f10`
admin_pass=`echo "$i"|cut -d, -f11`
language=`echo "$i"|cut -d, -f12`
backend_frontname=`echo "$i"|cut -d, -f13`
mage_mode=`echo "$i"|cut -d, -f14`
currency=`echo "$i"|cut -d, -f15`
timezone=`echo "$i"|cut -d, -f16`
eshost=`echo "$i"|cut -d, -f17`
esport=`echo "$i"|cut -d, -f18`
esenableauth=`echo "$i"|cut -d, -f19`
esusername=`echo "$i"|cut -d, -f20`
espassword=`echo "$i"|cut -d, -f21`
esindexprefix=`echo "$i"|cut -d, -f22`

# path="/home/01-XXXXXXX-XXX/www/preprod-01"
# dbhost="localhost"
# dbname="db-preprod-01"
# dbuser="01-XXXXXXX-XXXX"
# dbpass="XXX"
# base_url="https://preprod-01.com/"
# admin_firstname="FirstName"
# admin_lastname="LastName"
# admin_email="email@domain.com"
# admin_username="admin"
# admin_pass="XXXXXX"
# language="fr_FR"
# backend_frontname="admin"
# mage_mode="developer"
# currency="EUR"
# timezone="Europe/Paris"
# eshost="localhost"
# esport="41653"
# esenableauth="1"
# esusername="es"
# espassword="XXXXXX"
# esindexprefix="preprod-01.magento2"

composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition $path;
php -d memory_limit=-1 $path/bin/magento setup:install --base-url=$base_url --db-host=$dbhost --db-name=$dbname --db-user=$dbuser --db-password=$dbpass --admin-firstname=$admin_firstname --admin-lastname=$admin_lastname --admin-email=$admin_email --admin-user=$admin_username --admin-password=$admin_pass --language=$language --backend-frontname=$backend_frontname --currency=$currency --timezone=$timezone --magento-init-params="MAGE_MODE=$mage_mode" --elasticsearch-host $eshost --elasticsearch-port $esport --elasticsearch-enable-auth $esenableauth --elasticsearch-username $esusername --elasticsearch-password $espassword --elasticsearch-index-prefix $esindexprefix;
#Without Elasticsearch
#php -d memory_limit=-1 $path/bin/magento setup:install --base-url=$base_url --db-host=$dbhost --db-name=$dbname --db-user=$dbuser --db-password=$dbpass --admin-firstname=$admin_firstname --admin-lastname=$admin_lastname --admin-email=$admin_email --admin-user=$admin_username --admin-password=$admin_pass --language=$language --backend-frontname=$backend_frontname --currency=$currency --timezone=$timezone --magento-init-params="MAGE_MODE=$mage_mode";
php -d memory_limit=-1 $path/bin/magento setup:static-content:deploy -f;
php -d memory_limit=-1 $path/bin/magento module:disable Magento_TwoFactorAuth &&  setup:di:compile && chown -R 01-tl71486-1672. .

done
