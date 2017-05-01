#!/usr/bin/env bash
set -e

echo "Fetching Logstash..."
sudo curl -L -o /tmp/logstash.deb https://artifacts.elastic.co/downloads/logstash/logstash-${LOGSTASH_VERSION}.deb

echo "Installing Logstash..."
sudo apt-get install -y /tmp/logstash.deb
sudo rm /tmp/logstash.deb

cd /usr/share/logstash
sudo chown logstash:logstash -R .

sudo /usr/share/logstash/bin/logstash-plugin install logstash-input-beats

echo "Logstash installed."
