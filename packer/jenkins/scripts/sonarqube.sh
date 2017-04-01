#!/usr/bin/env bash
set -e

echo "Fetching SonarQube..."
sudo curl -L -o sonarqube.zip https://sonarsource.bintray.com/Distribution/sonarqube/sonarqube-6.3.zip

echo "Installing SonarQube..."
sudo unzip -d /opt sonarqube.zip 
