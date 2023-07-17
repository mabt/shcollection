#!/bin/bash                                                                                                                                                                                                                                                                                                                                                                                                                          

PATH=/home/mb99999-1856-dev-05/www/mb99999-1856-dev-05
VERSION=2.4.3-p2

# https://experienceleague.adobe.com/docs/commerce-operations/installation-guide/system-requirements.html                                                                                                                                                                                                                                                                                                                            

composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition=$VERSION $PATH;

php -d memory_limit=-1 $PATH/bin/magento setup:install --language='fr_FR' \
--timezone='Europe/Paris' \
--db-host='localhost' \
--db-name='dev-05' \
--db-user='dev-05' \
--db-password='XXXXXX' \
--base-url='https://XXXXXX/' \
--use-rewrites='1' \
--use-secure='0' \
--use-secure-admin='1' \
--admin-user='admin' \
--admin-lastname='NOM' \
--admin-firstname='PRENOM' \
--admin-email='support@fast-mage.com' \
--admin-password='XXXXXX' \
--session-save='files' \
--backend-frontname='adminyXXXXXX' \
--currency='EUR' \
--elasticsearch-host '127.0.0.1' \
--elasticsearch-port '41660' \
--elasticsearch-username 'es' \
--elasticsearch-password 'XXXXXX' \
--elasticsearch-enable-auth '1' \
--search-engine 'elasticsearch7' \
--elasticsearch-index-prefix 'magento2'

/usr/bin/php7.4 -d memory_limit=-1 $PATH/bin/magento setup:static-content:deploy -f;
/usr/bin/php7.4 -d memory_limit=-1 $PATH/bin/magento module:disable Magento_TwoFactorAuth
/usr/bin/php7.4 -d memory_limit=-1 $PATH/bin/magento setup:di:compile
