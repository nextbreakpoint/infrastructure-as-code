#!/usr/bin/env bash
set -e

echo "Fetching Elasticsearch..."
sudo curl -L -o /tmp/elastic.deb https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTICSEARCH_VERSION}.deb

echo "Installing Elasticsearch..."
sudo apt-get install -y /tmp/elastic.deb
sudo rm /tmp/elastic.deb

cd /usr/share/elasticsearch
sudo chown elasticsearch:elasticsearch -R .

sudo chown elasticsearch:elasticsearch -R /usr/share/elasticsearch
sudo chown elasticsearch:elasticsearch -R /etc/elasticsearch

sudo mkdir -p /mnt/elasticsearch/logs
sudo chown elasticsearch:elasticsearch -R /mnt/elasticsearch/logs

sudo mkdir -p /mnt/elasticsearch/data
sudo chown elasticsearch:elasticsearch -R /mnt/elasticsearch/data

sudo /usr/share/elasticsearch/bin/elasticsearch-plugin install --batch discovery-ec2

sudo echo "elasticsearch soft nofile 128000" >> /etc/security/limits.conf
sudo echo "elasticsearch hard nofile 128000" >> /etc/security/limits.conf
sudo echo "root soft nofile 128000" >> /etc/security/limits.conf
sudo echo "root hard nofile 128000" >> /etc/security/limits.conf

sudo echo "fs.file-max = 500000" >> /etc/sysctl.conf

echo "Elasticsearch installed."
