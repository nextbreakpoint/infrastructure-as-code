#!/usr/bin/env bash
set -e

echo "Fetching Kibana..."
sudo curl -L -o /tmp/kibana.deb https://artifacts.elastic.co/downloads/kibana/kibana-${KIBANA_VERSION}-amd64.deb

echo "Installing Kibana..."
sudo apt-get install -y /tmp/kibana.deb
sudo rm /tmp/kibana.deb

cd /usr/share/kibana
sudo chown kibana:kibana -R .

echo "Kibana installed."
