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


ES_PATH_CONF=/etc/elasticsearch/mn93237-1690 /usr/share/elasticsearch/bin/elasticsearch-plugin install -f /root/analysis-icu-7.12.0.zip 

# if it doesn't works dl from : https://www.elastic.co/guide/en/elasticsearch/plugins/current/plugin-management-custom-url.html

wget https://artifacts.elastic.co/downloads/elasticsearch-plugins/analysis-icu/analysis-icu-7.12.0.zip
wget https://artifacts.elastic.co/downloads/elasticsearch-plugins/analysis-phonetic/analysis-phonetic-7.12.0.zip

ES_PATH_CONF=/etc/elasticsearch/mn93237-1690 /usr/share/elasticsearch/bin/elasticsearch-plugin install file:/root/analysis-icu-7.12.0.zip 
ES_PATH_CONF=/etc/elasticsearch/mn93237-1690 /usr/share/elasticsearch/bin/elasticsearch-plugin install file:/root/analysis-phonetic-7.12.0.zip 
systemctl restart elasticsearch-mn93237-1690.service
