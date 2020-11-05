#!/bin/bash

apt update && apt-get install -y varnish

curl https://raw.githubusercontent.com/mabt/shcollection/master/varnish/varnishncsa-m2dev.service --output /lib/systemd/system/varnishncsa-m2dev.service
curl https://raw.githubusercontent.com/mabt/shcollection/master/varnish/varnish-m2dev.service --output /lib/systemd/system/varnish-m2dev.service
curl https://raw.githubusercontent.com/mabt/shcollection/master/varnish/default.m2dev.vcl  --output /etc/varnish/default.m2dev.vcl

systemctl enable varnish-m2dev
systemctl daemon-reload
systemctl restart varnish-m2dev
