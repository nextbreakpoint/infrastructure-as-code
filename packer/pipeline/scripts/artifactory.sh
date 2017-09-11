#!/usr/bin/env bash
set -e

echo "Fetching Artifactory..."
sudo curl -L -o jfrog-artifactory-oss-${ARTIFACTORY_VERSION}.zip https://bintray.com/jfrog/artifactory/download_file?file_path=jfrog-artifactory-oss-${ARTIFACTORY_VERSION}.zip
sudo curl -L -o mysql-connector-java-${MYSQLCONNECTOR_VERSION}.zip https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${MYSQLCONNECTOR_VERSION}.zip 

echo "Artifactory prepared."
