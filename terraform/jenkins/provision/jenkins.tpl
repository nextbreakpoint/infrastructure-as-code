#!/bin/bash
set -e

sudo service jenkins stop

sudo mkdir -p ${pipeline_data_dir}/jenkins
sudo mkdir -p ${pipeline_data_dir}/sonarqube
sudo mkdir -p ${pipeline_data_dir}/sonarqube/data
sudo mkdir -p ${pipeline_data_dir}/sonarqube/temp
sudo mkdir -p ${pipeline_data_dir}/mysql/data
sudo mkdir -p ${pipeline_data_dir}/artifactory/data/filestore

sudo mount ${volume_name}1 ${pipeline_data_dir}
echo "${volume_name}1 ${pipeline_data_dir} ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab >/dev/null

sudo rm -fR /var/lib/jenkins

sudo ln -s ${pipeline_data_dir}/jenkins /var/lib/jenkins

sudo chown -R jenkins:jenkins /var/lib/jenkins/

sudo -u jenkins docker run hello-world

sudo service jenkins start

sudo cat <<EOF >/tmp/sonar
#!/bin/sh
#
# rc file for SonarQube
#
# chkconfig: 345 96 10
# description: SonarQube system (www.sonarsource.org)
#
### BEGIN INIT INFO
# Provides: sonar
# Required-Start: $network
# Required-Stop: $network
# Default-Start: 3 4 5
# Default-Stop: 0 1 2 6
# Short-Description: SonarQube system (www.sonarsource.org)
# Description: SonarQube system (www.sonarsource.org)
### END INIT INFO
 
/usr/bin/sonar \$*
EOF
sudo cp /tmp/sonar /etc/init.d/sonar

sudo cp /opt/sonarqube-6.3/conf/sonar.properties /opt/sonarqube-6.3/conf/sonar.properties.bak

sudo cat <<EOF >/tmp/sonar.properties
sonar.jdbc.username=sonar
sonar.jdbc.password=sonar
sonar.jdbc.url=jdbc:mysql://localhost:3306/sonar?useUnicode=true&characterEncoding=utf8&rewriteBatchedStatements=true&useConfigs=maxPerformance&useSSL=false
sonar.path.data=${pipeline_data_dir}/sonarqube/data
sonar.path.temp=${pipeline_data_dir}/sonarqube/temp
EOF
sudo cp /tmp/sonar.properties /opt/sonarqube-6.3/conf/sonar.properties 

sudo service mysql stop

sudo rm -fR /var/lib/mysql
sudo sudo ln -s ${pipeline_data_dir}/mysql/data /var/lib/mysql
sudo chown -R mysql:mysql ${pipeline_data_dir}/mysql/data
sudo chown mysql:mysql /var/lib/mysql

sudo cat <<EOF >/tmp/alias
alias /var/lib/mysql/ -> /mnt/pipeline/mysql/data,
EOF
sudo cp /tmp/alias /etc/apparmor.d/tunables/alias 
sudo service apparmor restart

sudo service mysql start

sudo ln -s /opt/sonarqube-6.3/bin/linux-x86-64/sonar.sh /usr/bin/sonar
sudo chmod 755 /etc/init.d/sonar
sudo update-rc.d sonar defaults
sudo service sonar start

sudo curl -L -o jfrog-artifactory-oss-5.2.0.zip https://bintray.com/jfrog/artifactory/download_file?file_path=jfrog-artifactory-oss-5.2.0.zip

sudo unzip jfrog-artifactory-oss-5.2.0.zip -d /opt
sudo /opt/artifactory-oss-5.2.0/bin/installService.sh 

sudo service artifactory stop

sudo rm -fR /opt/artifactory-oss-5.2.0/data
sudo sudo ln -s ${pipeline_data_dir}/artifactory/data /opt/artifactory-oss-5.2.0/data
sudo chown -R artifactory:artifactory ${pipeline_data_dir}/artifactory
sudo chown artifactory:artifactory /opt/artifactory-oss-5.2.0/data

#sudo cat <<EOF >/tmp/binarystore.xml
#<config version="1">
#    <chain template="file-system"/>
#    <provider id="file-system" type="file-system">
#        <fileStoreDir>/mnt/pipeline/artifactory/data/filestore</fileStoreDir>
#    </provider>
#</config>
#EOF
#sudo cp /tmp/binarystore.xml /opt/artifactory-oss-5.2.0/etc/binarystore.xml

sudo update-rc.d artifactory defaults 95 10

sudo sed -i 's/127.0.0.1 .*$/127.0.0.1 localhost '$(hostname)'/g' /etc/hosts

sudo service artifactory start

echo "Done"
