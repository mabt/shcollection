#!/bin/bash

apt-get install -y apt-transport-https
apt-get install -y software-properties-common wget gnupg
wget -q -O - https://packages.grafana.com/gpg.key | apt-key add -

echo "deb https://packages.grafana.com/oss/deb stable main" | tee -a /etc/apt/sources.list.d/grafana.list

apt-get update && apt-get install grafana -y

systemctl enable grafana
systemctl start grafana
