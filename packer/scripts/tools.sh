#!/usr/bin/env bash
set -e

echo "Updating packages..."
sudo apt-get update -y

echo "Installing tools..."
sudo apt-get install -y vim curl wget unzip screen python dnsmasq dnsutils
sudo apt-get install -y apt-transport-https ca-certificates software-properties-common

echo "Tools installed."
