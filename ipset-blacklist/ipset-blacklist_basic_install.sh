#!/bin/bash

# https://github.com/trick77/ipset-blacklist
# http://ipverse.net/

apt update && apt-get install -y ipset
wget -O /usr/local/sbin/update-blacklist.sh https://raw.githubusercontent.com/trick77/ipset-blacklist/master/update-blacklist.sh
chmod +x /usr/local/sbin/update-blacklist.sh
mkdir -p /etc/ipset-blacklist ; wget -O /etc/ipset-blacklist/ipset-blacklist.conf https://raw.githubusercontent.com/trick77/ipset-blacklist/master/ipset-blacklist.conf
/usr/local/sbin/update-blacklist.sh /etc/ipset-blacklist/ipset-blacklist.conf
(crontab -l | grep . ; echo -e "11 0 * * * "/usr/local/acme.sh"/acme.sh --cron --home "/usr/local/acme.sh" > /dev/null\n") | crontab -
