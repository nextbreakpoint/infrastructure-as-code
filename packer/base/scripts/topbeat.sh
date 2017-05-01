#!/usr/bin/env bash
set -e

echo "Fetching Topbeat..."
sudo curl -L -o /tmp/topbeat.deb https://download.elastic.co/beats/topbeat/topbeat_${TOPBEAT_VERSION}_amd64.deb

echo "Installing Topbeat..."
sudo dpkg -i /tmp/topbeat.deb
sudo rm /tmp/topbeat.deb

echo "Topbeat installed."
