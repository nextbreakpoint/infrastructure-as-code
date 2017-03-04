#!/usr/bin/env bash

set -e

echo "Fetching Consul..."
cd /tmp
curl -L -o consul.zip https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip

echo "Installing Consul..."
unzip consul.zip >/dev/null
sudo chmod +x consul
sudo mv consul /usr/local/bin/consul
sudo mkdir -p /etc/consul.d
sudo mkdir -p /etc/service
sudo mkdir -p /mnt/consul
sudo mkdir -p /var/consul
sudo chmod +rwx /mnt/consul
sudo chmod +rwx /var/consul
sudo chown -R ubuntu:ubuntu /mnt/consul
sudo chown -R ubuntu:ubuntu /var/consul

echo "Fetching Consul template..."
curl -L -o consul-template.zip https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip

echo "Installing Consul template..."
unzip consul-template.zip >/dev/null
sudo mv consul-template /opt/consul-template

echo "Fetching Consul UI..."
curl -L -o consul-ui.zip https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_web_ui.zip

echo "Installing Consul UI..."
sudo mkdir -p /mnt/consul/ui
sudo mv consul-ui.zip /mnt/consul/ui
cd /mnt/consul/ui
unzip consul-ui.zip >/dev/null
