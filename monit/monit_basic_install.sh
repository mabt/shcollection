#!/bin/bash

apt update && apt-get install -y monit

systemctl enable monit

