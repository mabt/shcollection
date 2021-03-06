#!/bin/bash                                                                                                                                                                                                                                                                            

NAME="prod-m2"
PORT="10081"
PORT2="10082"
#PORT3="8080" TODO pour apache2

apt-get update && apt-get install -y curl varnish                                                                                                                                                                                                                                    

a2enmod remoteip

curl https://raw.githubusercontent.com/mabt/shcollection/master/varnish/varnishncsa-666.service --output /lib/systemd/system/varnishncsa-$NAME.service
curl https://raw.githubusercontent.com/mabt/shcollection/master/varnish/varnish-666.service --output /lib/systemd/system/varnish-$NAME.service
curl https://raw.githubusercontent.com/mabt/shcollection/master/varnish/default.666.vcl  --output /etc/varnish/default.$NAME.vcl
curl https://raw.githubusercontent.com/mabt/shcollection/master/varnish/apache2-vhost-varnished-example.conf --output /etc/apache2/varnish-example-$NAME.conf
curl https://raw.githubusercontent.com/mabt/shcollection/master/varnish/apache2-varnish.conf --output /etc/apache2/conf-enabled/varnish.conf


sed -i 's/666/'${NAME}'/g' /lib/systemd/system/varnishncsa-$NAME.service
sed -i 's/666/'${NAME}'/g' /lib/systemd/system/varnish-$NAME.service
sed -i 's/55555/'${PORT}'/g' /lib/systemd/system/varnish-$NAME.service
sed -i 's/77777/'${PORT2}'/g' /lib/systemd/system/varnish-$NAME.service

[[ -e /var/lib/varnish/${NAME} ]] || mkdir /var/lib/varnish/$NAME
chown varnish. /var/lib/varnish/$NAME

systemctl daemon-reload
systemctl enable varnish-$NAME
systemctl daemon-reload
systemctl restart varnish-$NAME

echo ""
echo "systemctl status varnish-${NAME}.service"
echo ""
echo "Port :"
echo $PORT
