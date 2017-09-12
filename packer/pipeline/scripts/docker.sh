#!/usr/bin/env bash
set -e

echo "Preparing Docker..."
sudo apt-get install -y apt-transport-https ca-certificates software-properties-common

echo "Fetching Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update

echo "Installing Docker..."
sudo apt-cache madison docker-ce
sudo apt-get install -y docker-ce

echo "Docker installed."
