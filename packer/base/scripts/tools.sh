#!/usr/bin/env bash
set -e

echo "Updating packages..."
sudo apt-get update

echo "Installing tools..."
sudo apt-get install -y vim curl wget unzip screen python

echo "Tools installed."
