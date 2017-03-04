#!/bin/bash -eux

set -e

sudo apt-get install -y software-properties-common
sudo add-apt-repository -y ppa:webupd8team/java
sudo apt-get update

echo "Accept license"
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
sudo apt-get install -y oracle-java8-installer

sudo apt-get install oracle-java8-set-default

echo "Check installation"
java -version
javac -version
