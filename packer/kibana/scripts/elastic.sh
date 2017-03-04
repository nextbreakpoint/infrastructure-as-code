#!/usr/bin/env bash

set -e

echo "Fetching Elasticsearch..."
cd /tmp
curl -L -o elastic.deb https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTIC_VERSION}.deb

echo "Installing Elasticsearch..."
sudo apt-get install -y ./elastic.deb

rm elastic.deb

cd /usr/share/elasticsearch
sudo chown elasticsearch:elasticsearch -R .

ls -lR /usr/share/elasticsearch

echo "Installing aws plugin..."
sudo apt-get install -y expect
ls -al /tmp/awsplugin.sh
echo "chmod awsplugin"
sudo chmod +x /tmp/awsplugin.sh
echo "running aws plugin"
/tmp/awsplugin.sh
echo "done running aws plugin"

#sudo sed -i 's/#MAX_LOCKED_MEMORY=unlimited/MAX_LOCKED_MEMORY=unlimited/' /usr/share/elasticsearch/config/elasticsearch.yml
