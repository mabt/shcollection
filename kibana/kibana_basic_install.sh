#!/bin/bash

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
[ ! -f /etc/apt/sources.list.d/elastic-7.x.list] && echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo -a /etc/apt/sources.list.d/elastic-7.x.list

apt-get install kibana
