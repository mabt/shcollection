#!/bin/bash

# m2 sessions : https://experienceleague.adobe.com/docs/commerce-operations/configuration-guide/cache/redis/redis-session.html
# m2 cache : https://experienceleague.adobe.com/docs/commerce-operations/configuration-guide/cache/redis/redis-pg-cache.html

PATH=path
HOST=127.0.0.1
PORT=6134
PASS=PASS
DB_SESSION=1
DB_CACHE_1=2
DB_CACHE_2=3
PHP=/usr/bin/php7.4
SESSION_SAVE_REDIS_MAX_CONCURENCY=60

echo ""
echo "List of db used by redis"
/usr/bin/redis-cli -p $PORT -a $PASS INFO  | /usr/bin/grep -iE "db.:keys"
echo ""
echo "New db configuration"
echo DB_SESSION : $DB_SESSION
echo DB_CACHE_1 : $DB_CACHE_1
echo DB_CACHE_2 : $DB_CACHE_2
echo ""

read -p "Press enter to continue"

$PHP $PATH/bin/magento setup:config:set --session-save=redis --session-save-redis-host=$HOST --session-save-redis-log-level=4 --session-save-redis-db=$DB_SESSION --session-save-redis-password=$PASS --session-save-redis-port=$PORT --session-save-redis-disable-locking=0 --session-save-redis-max-concurrency=$SESSION_SAVE_REDIS_MAX_CONCURENCY
$PHP $PATH/bin/magento setup:config:set --cache-backend=redis --cache-backend-redis-server=$HOST --cache-backend-redis-db=$DB_CACHE_1 --cache-backend-redis-password=$PASS --cache-backend-redis-port=$PORT
$PHP $PATH/bin/magento setup:config:set --page-cache=redis --page-cache-redis-server=$HOST --page-cache-redis-db=$DB_CACHE_2 --page-cache-redis-password=$PASS --page-cache-redis-port=$PORT

echo "done."
