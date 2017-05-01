#!/usr/bin/env bash
set -e

echo "Installing MySQL..."
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password admin'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password admin'
sudo apt-get install -y mysql-server

echo "MySQL installed."
