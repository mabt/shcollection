#!/bin/bash

NAME="prod-m2"
WEBSITE="ServerName example.com"
PORT="6092"
PATH="///"

apt update && apt-get install -y varnish

curl https://raw.githubusercontent.com/mabt/shcollection/master/varnish/varnishncsa-666.service --output /lib/systemd/system/varnishncsa-$NAME.service
curl https://raw.githubusercontent.com/mabt/shcollection/master/varnish/varnish-666.service --output /lib/systemd/system/varnish-$NAME.service
curl https://raw.githubusercontent.com/mabt/shcollection/master/varnish/default.666.vcl  --output /etc/varnish/default.$NAME.vcl
curl https://raw.githubusercontent.com/mabt/shcollection/master/varnish/apache2-vhost-varnished-exemple.conf --output /etc/apache2/sites-available/apache2-vhost-varnished-exemple.con

sed -i 's/666/$NAME/g' /lib/systemd/system/varnishncsa-$NAME.service
sed -i 's/666/$NAME/g' /lib/systemd/system/varnish-$NAME.service
sed -i 's/ServerName example.com/$WEBSITE/g' /etc/apache2/sites-available/apache2-vhost-varnished-exemple.con
sed -i 's/6091/$PORT/g' /etc/apache2/sites-available/apache2-vhost-varnished-exemple.con
sed -i 's/\/home\/user\/www\/example.com/$PATH/g' /etc/apache2/sites-available/apache2-vhost-varnished-exemple.con

systemctl enable varnish-$NAME
systemctl daemon-reload
systemctl restart varnish-$NAME
