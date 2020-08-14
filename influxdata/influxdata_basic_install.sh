#!/bin/bash

wget -qO- https://repos.influxdata.com/influxdb.key | sudo apt-key add -
source /etc/os-release
echo "deb https://repos.influxdata.com/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/influxdb.list

apt-get update && apt-get install -y influxdb
systemctl enable influxdb
systemctl daemon-reload
systemctl start influxdb
