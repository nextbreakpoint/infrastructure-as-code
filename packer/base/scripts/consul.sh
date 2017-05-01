#!/usr/bin/env bash
set -e

echo "Fetching Consul..."
sudo curl -L -o /tmp/consul.zip https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip

echo "Installing Consul..."
sudo unzip -d /tmp /tmp/consul.zip >/dev/null
sudo chmod +x /tmp/consul
sudo mv /tmp/consul /usr/local/bin/consul
sudo mkdir -p /etc/consul.d
sudo mkdir -p /etc/service
sudo mkdir -p /mnt/consul
sudo mkdir -p /var/consul
sudo chmod +rwx /mnt/consul
sudo chmod +rwx /var/consul
sudo chown -R ubuntu:ubuntu /mnt/consul
sudo chown -R ubuntu:ubuntu /var/consul
sudo rm /tmp/consul.zip

echo "Consul installed."
