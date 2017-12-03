#!/usr/bin/env bash
set -e

echo "Updating packages..."
sudo yum update -y

echo "Installing tools..."
sudo yum install -y vim curl wget unzip screen python dnsmasq bind-utils

echo "Tools installed."
