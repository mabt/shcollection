#!/bin/bash

# See more : https://github.com/allinurl/goaccess

apt-get install -y libncursesw5-dev libgeoip-dev
cd /root/
wget https://tar.goaccess.io/goaccess-1.4.tar.gz
tar -xzvf goaccess-1.4.tar.gz
cd goaccess-1.4/
./configure --enable-utf8 --enable-geoip=legacy
make
make install

sed -i '/time-format %H:%M:%S/s/^#//g' /usr/local/etc/goaccess/goaccess.conf
sed -i '/log-format %h %^\[%d:%t %^\] "%r" %s %b "%R" "%u"/s/^#//g' /usr/local/etc/goaccess/goaccess.con
sed -i '/date-format %d\/%b\/%Y/s/^#//g' /usr/local/etc/goaccess/goaccess.conf
