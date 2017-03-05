#!/usr/bin/env bash
set -e

echo "Fetching Logstash..."
cd /tmp
sudo curl -L -o logstash.deb https://artifacts.elastic.co/downloads/logstash/logstash-${LOGSTASH_VERSION}.deb

echo "Installing Logstash..."
sudo apt-get install -y ./logstash.deb

sudo rm logstash.deb

cd /usr/share/logstash
sudo chown logstash:logstash -R .

sudo /usr/share/logstash/bin/logstash-plugin install logstash-input-beats
