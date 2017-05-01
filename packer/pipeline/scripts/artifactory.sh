#!/usr/bin/env bash
set -e

echo "Fetching Artifactory..."
sudo curl -L -o jfrog-artifactory-oss-5.2.0.zip https://bintray.com/jfrog/artifactory/download_file?file_path=jfrog-artifactory-oss-5.2.0.zip
sudo curl -L -o mysql-connector-java-5.1.41.zip https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.41.zip 

echo "Artifactory prepared."
