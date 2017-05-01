#!/usr/bin/env bash
set -e

echo "Fetching Jenkins..."
sudo curl -L -o /tmp/jenkins.deb http://mirrors.jenkins-ci.org/debian/jenkins_2.58_all.deb

echo "Installing Jenkins..."
sudo apt-get install -y /tmp/jenkins.deb
sudo rm /tmp/jenkins.deb

echo "Adding Jenkins to Docker group..."
sudo usermod -aG docker jenkins

echo "Jenkins installed."
