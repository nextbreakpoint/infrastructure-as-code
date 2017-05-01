#!/usr/bin/env bash
set -e

echo "Fetching Cassandra..."
sudo curl -L http://debian.datastax.com/debian/repo_key | sudo apt-key add -
echo "deb http://debian.datastax.com/datastax-ddc ${CASSANDRA_VERSION} main" | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list

echo "Installing Cassandra..."
sudo apt-get update
sudo apt-get install -y datastax-ddc
sudo service cassandra stop
sudo rm -rf /var/lib/cassandra/data/system/*

echo "Cassandra installed."
