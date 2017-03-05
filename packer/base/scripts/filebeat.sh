#!/usr/bin/env bash
set -e

echo "Fetching Filebeat..."
sudo curl -L -o filebeat.deb https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${FILEBEAT_VERSION}-amd64.deb

echo "Installing Filebeat..."
sudo apt-get install -y ./filebeat.deb

sudo rm filebeat.deb
