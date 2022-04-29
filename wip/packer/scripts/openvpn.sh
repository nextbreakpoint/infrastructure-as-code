#!/usr/bin/env bash

set -e

echo "Installing OpenVPN..."

#sudo useradd -s /bin/bash -p $(echo password | openssl passwd -1 -stdin) openvpn
#sudo usermod -aG sudo openvpn

sudo apt-get install -y ufw openvpn

# gunzip -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz | sudo tee ~/server.conf
# cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf ~/client.conf

echo "OpenVPN installed."
