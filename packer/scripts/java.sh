#!/usr/bin/env bash
set -e

echo "Installing Java 8..."
sudo apt-get install -y software-properties-common
sudo add-apt-repository -y ppa:webupd8team/java
sudo apt-get update -y

echo "Accepting license..."
sudo echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
sudo apt-get install -y oracle-java8-installer

sudo apt-get install -y oracle-java8-set-default

echo "Checking installation..."
java -version
javac -version

echo "Java 8 installed."
