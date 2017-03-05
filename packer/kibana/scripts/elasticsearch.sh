#!/usr/bin/env bash
set -e

echo "Fetching Elasticsearch..."
cd /tmp
sudo curl -L -o elastic.deb https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTIC_VERSION}.deb

echo "Installing Elasticsearch..."
sudo apt-get install -y ./elastic.deb

sudo rm elastic.deb

cd /usr/share/elasticsearch
sudo chown elasticsearch:elasticsearch -R .

sudo chown elasticsearch:elasticsearch -R /usr/share/elasticsearch
sudo chown elasticsearch:elasticsearch -R /etc/elasticsearch

sudo mkdir -p /mnt/elasticsearch/logs
sudo chown elasticsearch:elasticsearch -R /mnt/elasticsearch/logs

sudo mkdir -p /mnt/elasticsearch/data
sudo chown elasticsearch:elasticsearch -R /mnt/elasticsearch/data

sudo /usr/share/elasticsearch/bin/elasticsearch-plugin install --batch discovery-ec2

