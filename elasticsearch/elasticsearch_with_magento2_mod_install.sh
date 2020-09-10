#!/bin/bash

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

[ ! -f /etc/apt/sources.list.d/elastic-7.x.list ] && echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list

sudo apt-get update
sudo apt-get install -y apt-transport-https

apt-get update && apt-get -y install elasticsearch

systemctl enable elasticsearch
systemctl daemon-reload
systemctl start elasticsearch

/usr/share/elasticsearch/bin/elasticsearch-plugin -s install analysis-phonetic
/usr/share/elasticsearch/bin/elasticsearch-plugin -s install analysis-icu
