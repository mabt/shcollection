#!/bin/bash                                                                                                                                                                                                                                                                            

NAME="prod-m2"
PORT="10081"
PORT2="10082"
apt-get update && apt-get install -y curl varnish                                                                                                                                                                                                                                    

curl https://raw.githubusercontent.com/mabt/shcollection/master/varnish/varnishncsa-666.service --output /lib/systemd/system/varnishncsa-$NAME.service
curl https://raw.githubusercontent.com/mabt/shcollection/master/varnish/varnish-666.service --output /lib/systemd/system/varnish-$NAME.service
curl https://raw.githubusercontent.com/mabt/shcollection/master/varnish/default.666.vcl  --output /etc/varnish/default.$NAME.vcl
curl https://raw.githubusercontent.com/mabt/shcollection/master/varnish/apache2-vhost-varnished-exemple.conf --output /etc/apache2/varnish-example.conf

sed -i 's/666/'${NAME}'/g' /lib/systemd/system/varnishncsa-$NAME.service
sed -i 's/666/'${NAME}'/g' /lib/systemd/system/varnish-$NAME.service
sed -i 's/66666/'${PORT}'/g' /lib/systemd/system/varnish-$NAME.service
sed -i 's/77777/'${PORT}'/g' /lib/systemd/system/varnish-$NAME.service

mkdir /var/lib/varnish/$NAME
chown varnish. /var/lib/varnish/$NAME

systemctl enable varnish-$NAME
systemctl daemon-reload
systemctl restart varnish-$NAME

