#!/usr/bin/env bash
set -e

echo "Fetching Elasticsearch..."
sudo curl -L -o /tmp/elastic.deb https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTIC_VERSION}.deb

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

echo "Elasticsearch installed."
