#!/bin/bash -eux

set -e

sudo apt-get update

sudo apt-get install -y vim curl wget unzip screen python

sudo echo "elasticsearch soft nofile 128000" >> /etc/security/limits.conf
sudo echo "elasticsearch hard nofile 128000" >> /etc/security/limits.conf
sudo echo "root soft nofile 128000" >> /etc/security/limits.conf
sudo echo "root hard nofile 128000" >> /etc/security/limits.conf

sudo echo "fs.file-max = 500000" >> /etc/sysctl.conf
