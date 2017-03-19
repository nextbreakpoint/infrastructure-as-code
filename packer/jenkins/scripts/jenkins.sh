#!/usr/bin/env bash
set -e

echo "Fetching Jenkins..."
sudo curl -L -o jenkins.deb http://mirrors.jenkins-ci.org/debian/jenkins_2.50_all.deb

echo "Installing Jenkins..."
sudo apt-get install -y ./jenkins.deb

sudo rm jenkins.deb

echo "Adding Jenkins to Docker group..."
sudo usermod -aG docker jenkins
