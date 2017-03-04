#!/usr/bin/env bash

set -e

echo "Fetching Kibana..."
cd /tmp
curl -L -o kibana.deb https://artifacts.elastic.co/downloads/kibana/kibana-${KIBANA_VERSION}-amd64.deb

echo "Installing Kibana..."
sudo apt-get install -y ./kibana.deb

rm kibana.deb

cd /usr/share/kibana
sudo chown kibana:kibana -R .

ls -lR /usr/share/kibana
