#!/usr/bin/env bash
set -e

echo "Fetching Filebeat..."
sudo curl -L -o /tmp/filebeat.deb https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${FILEBEAT_VERSION}-amd64.deb

echo "Installing Filebeat..."
sudo apt-get install -y /tmp/filebeat.deb
sudo rm /tmp/filebeat.deb

echo "Filebeat installed."
