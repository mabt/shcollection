#!/bin/bash

apt-get install -y libncursesw5-dev libgeoip-dev
cd /root/
wget https://tar.goaccess.io/goaccess-1.4.tar.gz
tar -xzvf goaccess-1.4.tar.gz
cd goaccess-1.4/
./configure --enable-utf8 --enable-geoip=legacy
make
make install
