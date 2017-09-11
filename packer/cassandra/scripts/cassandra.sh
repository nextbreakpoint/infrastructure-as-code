#!/usr/bin/env bash
set -e

echo "Fetching Cassandra..."
sudo echo "deb http://www.apache.org/dist/cassandra/debian ${CASSANDRA_VERSION}x main" | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list
sudo curl https://www.apache.org/dist/cassandra/KEYS | sudo apt-key add -

echo "Installing Cassandra..."
sudo apt-get update -y
sudo apt-get install -y cassandra
sudo service cassandra stop
sudo rm -rf /var/lib/cassandra/data/system/*

echo "Cassandra installed."
