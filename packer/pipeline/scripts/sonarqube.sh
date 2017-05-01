#!/usr/bin/env bash
set -e

echo "Fetching SonarQube..."
sudo curl -L -o /tmp/sonarqube.zip https://sonarsource.bintray.com/Distribution/sonarqube/sonarqube-6.3.zip

echo "Installing SonarQube..."
sudo unzip -d /opt /tmp/sonarqube.zip 
sudo rm /tmp/sonarqube.zip 

echo "SonarQube installed."
