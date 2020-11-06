#!/bin/bash

composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition .

#bin/magento setup:install --base-url=https://devm2.exemple.com/ --db-host=localhost --db-name=devm2 --db-user=devm2 --db-password=passwd --admin-firstname=admin --admin-lastname=admin --admin-email=admin@admin.com --admin-user=admin --admin-password=passwd --language=fr_FR --currency=EUR --timezone=Europe/Paris --use-rewrites=1

bin/magento setup:install \
--base-url=https://devm2.exemple.com/ \
--db-host=localhost \
--db-name=devm2 \
--db-user=devm2 \
--db-password=passwd --admin-firstname=admin \
--admin-lastname=admin \
--admin-email=admin@admin.com \
--admin-user=admin \
--admin-password=passwd \
--language=fr_FR \
--currency=EUR \
--timezone=Europe/Paris \
--use-rewrites=1

magerun2 setup:upgrade
magerun2 indexer:reindex
magerun2 setup:static-content:deploy
magerun2 setup:di:compile
magerun2 deploy:mode:set production
magerun2 deploy:mode:set developer
magerun2 setup:static-content:deploy
bin/magento sampledata:deploy
magerun2 cache:clean && magerun2 cache:f
