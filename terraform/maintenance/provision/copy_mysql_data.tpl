#!/usr/bin/env bash
set -e

echo "Installing MySQL..."
sudo apt-get update -y
sudo echo 'mysql-server mysql-server/root_password password admin' | debconf-set-selections
sudo echo 'mysql-server mysql-server/root_password_again password admin' | debconf-set-selections
sudo apt-get install -y mysql-server

echo "MySQL installed."

sudo mkdir -p /mnt/pipeline

sudo mount ${device_name}1 /mnt/pipeline

sudo service mysql stop

echo "MySQL copying data..."

sudo cp -R /var/lib/mysql /mnt/pipeline

sudo umount /mnt/pipeline

echo "MySQL data copied."
