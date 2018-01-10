#!/usr/bin/env bash
set -e

echo "Installing OpenVPN..."

sudo useradd -s /bin/bash -p $(echo password | openssl passwd -1 -stdin) openvpn
sudo usermod -aG sudo openvpn

sudo apt-get update -y
sudo apt-get install -y ufw openvpn easy-rsa

gunzip -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz | sudo tee ~/server.conf
cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf ~/base.conf

cat <<EOF | sudo tee /etc/openvpn/server.conf
port 1194
proto udp
dev tun

ca ca_cert.pem
cert server_cert.pem
key server_key.pem # This file should be kept secret

# Diffie hellman parameters.
# Generate your own with:
#   openssl dhparam -out dh2048.pem 2048
dh dh2048.pem

server 10.8.0.0 255.255.255.0

ifconfig-pool-persist ipp.txt

push "route 172.34.0.0 255.255.0.0"
push "route 172.32.0.0 255.255.0.0"

push "redirect-gateway def1 bypass-dhcp"

push "dhcp-option DNS 172.34.0.0"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"

keepalive 10 120

# Generate with:
#   openvpn --genkey --secret ta.key
#
# The server and each client must have
# a copy of this key.
# The second parameter should be '0'
# on the server and '1' on the clients.
tls-auth ta.key 0 # This file is secret
key-direction 0

cipher AES-128-CBC

auth SHA256

comp-lzo

max-clients 10

persist-key
persist-tun

user nobody
group nogroup

status openvpn-status.log

verb 3
EOF

cat <<EOF | sudo tee /etc/sysctl.conf
net.ipv4.ip_forward=1
EOF

cat <<EOF | sudo tee /etc/openvpn/client.conf
client
proto udp
dev tun

remote openvpn.nextbreakpoint.com 1194

resolv-retry infinite

nobind

#user nobody
#group nogroup

persist-key
persist-tun

#ca ca_cert.pem
#cert client_cert.pem
#key client_key.pem

remote-cert-tls server

#tls-auth ta.key 1
key-direction 1

cipher AES-128-CBC

auth SHA256

comp-lzo

script-security 3
#up /etc/openvpn/update-resolv-conf
#down /etc/openvpn/update-resolv-conf

verb 3
EOF

sudo sed -i "10i \*nat\n:POSTROUTING ACCEPT \[0:0\]\n-A POSTROUTING -s 10.8.0.0/8 -o eth0 -j MASQUERADE\nCOMMIT" /etc/ufw/before.rules

sudo sed -i 's/DEFAULT_FORWARD_POLICY=\"DROP\"/DEFAULT_FORWARD_POLICY=\"ACCEPT\"/g' /etc/default/ufw

cat <<EOF | sudo tee /etc/openvpn/build_config.sh
#!/bin/bash

KEY_DIR=~
OUTPUT_DIR=~
BASE_CONFIG=/etc/openvpn/client.conf

cat \${BASE_CONFIG} > \${OUTPUT_DIR}/\$1.ovpn
echo '<ca>' >> \${OUTPUT_DIR}/\$1.ovpn
cat \${KEY_DIR}/ca_cert.pem >> \${OUTPUT_DIR}/\$1.ovpn
echo '</ca>\n<cert>' >> \${OUTPUT_DIR}/\$1.ovpn
cat \${KEY_DIR}/\$1_cert.pem >> \${OUTPUT_DIR}/\$1.ovpn
echo '</cert>\n<key>' >> \${OUTPUT_DIR}/\$1.ovpn
cat \${KEY_DIR}/\$1_key.pem >> \${OUTPUT_DIR}/\$1.ovpn
echo '</key>\n<tls-auth>' >> \${OUTPUT_DIR}/\$1.ovpn
cat /etc/openvpn/ta.key >> \${OUTPUT_DIR}/\$1.ovpn
echo '</tls-auth>' >> \${OUTPUT_DIR}/\$1.ovpn
EOF

sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 53
sudo ufw allow 443
sudo ufw allow 1194/udp
sudo ufw enable

sudo systemctl start openvpn@server
sudo systemctl enable openvpn@server

sudo ip addr show tun0

sudo sh /etc/openvpn/build_config.sh client

echo "OpenVPN installed."
