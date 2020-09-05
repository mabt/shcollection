#!/bin/bash

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

[ ! -f /etc/apt/sources.list.d/elastic-7.x.list ] && echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list

sudo apt-get update
sudo apt-get install -y apt-transport-https

apt-get update && apt-get -y install elasticsearch

systemctl enable elasticsearsh
systemctl daemon-reload
systemctl start elasticsearsh

