#!/usr/bin/env bash

set -e

echo "Installing Logstash forwarder..."
echo 'deb http://packages.elasticsearch.org/logstashforwarder/debian stable main' | sudo tee /etc/apt/sources.list.d/logstashforwarder.list

wget -O - http://packages.elasticsearch.org/GPG-KEY-elasticsearch | sudo apt-key add -

apt-get update

apt-get install -y logstash-forwarder
