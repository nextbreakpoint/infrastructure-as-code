#!/usr/bin/env bash
set -e

echo "Installing MySQL..."
sudo apt-get update -y
echo 'mysql-server mysql-server/root_password password admin' | sudo debconf-set-selections
echo 'mysql-server mysql-server/root_password_again password admin' | sudo debconf-set-selections
sudo apt-get install -y mysql-server

echo "MySQL installed."

sudo mkdir -p /mnt/pipeline

sudo mount ${device_name}1 /mnt/pipeline

sudo mysqladmin -u root -p'admin' password ''

sudo rm script.sql

echo "DROP DATABASE artifactory;" >> script.sql
echo "CREATE DATABASE artifactory CHARACTER SET utf8 COLLATE utf8_bin;" >> script.sql
echo "CREATE USER IF NOT EXISTS 'artifactory' IDENTIFIED BY 'artifactory' PASSWORD EXPIRE NEVER;" >> script.sql
echo "GRANT ALL ON artifactory.* TO 'artifactory';" >> script.sql

echo "DROP DATABASE sonar;" >> script.sql
echo "CREATE DATABASE sonar CHARACTER SET utf8 COLLATE utf8_bin;" >> script.sql
echo "CREATE USER IF NOT EXISTS 'sonar' IDENTIFIED BY 'sonar' PASSWORD EXPIRE NEVER;" >> script.sql
echo "GRANT ALL ON sonar.* TO 'sonar';" >> script.sql

sudo mysql -u root < script.sql

sudo mysqladmin -u root password 'admin'

sudo service mysql stop

echo "MySQL copying data..."

sudo cp -R /var/lib/mysql /mnt/pipeline

sudo umount /mnt/pipeline

echo "MySQL data copied."
