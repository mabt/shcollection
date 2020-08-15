#!/bin/bash

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
[ ! -f /etc/apt/sources.list.d/elastic-7.x.list] && echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo -a /etc/apt/sources.list.d/elastic-7.x.list

apt-get install -y default-jre logstash

systemctl enable logstash
systemctl daemon-reload
systemctl start logstash
