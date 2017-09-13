#!/bin/bash
set -e

export PIPELINE_HOST=`ifconfig eth0 | grep "inet " | awk '{ print substr($2,6) }'`

sudo sed -i 's/127.0.0.1 .*$/127.0.0.1 localhost '$(hostname)'/g' /etc/hosts

sudo mkdir -p ${pipeline_data_dir}

sudo mount ${volume_name}1 ${pipeline_data_dir}
echo "${volume_name}1 ${pipeline_data_dir} ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab >/dev/null

sudo mkdir -p ${pipeline_data_dir}/jenkins
sudo mkdir -p ${pipeline_data_dir}/sonarqube
sudo mkdir -p ${pipeline_data_dir}/sonarqube/data
sudo mkdir -p ${pipeline_data_dir}/sonarqube/temp
sudo mkdir -p ${pipeline_data_dir}/mysql
sudo mkdir -p ${pipeline_data_dir}/artifactory/filestore
sudo mkdir -p ${pipeline_data_dir}/artifactory/access
sudo mkdir -p ${pipeline_data_dir}/artifactory/backup
sudo mkdir -p ${pipeline_data_dir}/artifactory/data

sudo service jenkins stop

sudo rm -fR /var/lib/jenkins
sudo ln -s ${pipeline_data_dir}/jenkins /var/lib/jenkins
sudo chown -R jenkins:jenkins ${pipeline_data_dir}/jenkins
sudo chown -R jenkins:jenkins /var/lib/jenkins

sudo -u jenkins docker run hello-world

sudo service mysql stop

sudo rm -fR /var/lib/mysql
sudo sudo ln -s ${pipeline_data_dir}/mysql /var/lib/mysql
sudo chown -R mysql:mysql ${pipeline_data_dir}/mysql
sudo chown -R mysql:mysql /var/lib/mysql

cat <<EOF >/tmp/alias
alias /var/lib/mysql/ -> /mnt/pipeline/mysql,
EOF
sudo cp /tmp/alias /etc/apparmor.d/tunables/alias

cat <<EOF >/tmp/sonar
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

sudo cp /opt/sonarqube-${sonarqube_version}/conf/sonar.properties /opt/sonarqube-${sonarqube_version}/conf/sonar.properties.bak

cat <<EOF >/tmp/sonar.properties
sonar.jdbc.username=sonar
sonar.jdbc.password=sonar
sonar.jdbc.url=jdbc:mysql://localhost:3306/sonar?useUnicode=true&characterEncoding=utf8&rewriteBatchedStatements=true&useConfigs=maxPerformance&useSSL=false
sonar.path.data=${pipeline_data_dir}/sonarqube/data
sonar.path.temp=${pipeline_data_dir}/sonarqube/temp
EOF
sudo cp /tmp/sonar.properties /opt/sonarqube-${sonarqube_version}/conf/sonar.properties

sudo ln -s /opt/sonarqube-${sonarqube_version}/bin/linux-x86-64/sonar.sh /usr/bin/sonar
sudo chmod 755 /etc/init.d/sonar
sudo update-rc.d sonar defaults

sudo unzip jfrog-artifactory-oss-${artifactory_version}.zip -d /opt

sudo rm -fR /opt/artifactory-oss-${artifactory_version}/filestore
sudo sudo ln -s ${pipeline_data_dir}/artifactory/filestore /opt/artifactory-oss-${artifactory_version}/filestore

sudo rm -fR /opt/artifactory-oss-${artifactory_version}/access
sudo sudo ln -s ${pipeline_data_dir}/artifactory/access /opt/artifactory-oss-${artifactory_version}/access

sudo rm -fR /opt/artifactory-oss-${artifactory_version}/backup
sudo sudo ln -s ${pipeline_data_dir}/artifactory/backup /opt/artifactory-oss-${artifactory_version}/backup

sudo rm -fR /opt/artifactory-oss-${artifactory_version}/data
sudo sudo ln -s ${pipeline_data_dir}/artifactory/data /opt/artifactory-oss-${artifactory_version}/data

sudo /opt/artifactory-oss-${artifactory_version}/bin/installService.sh
sudo chown -R artifactory:artifactory ${pipeline_data_dir}/artifactory
#sudo systemctl start artifactory.service
#sudo update-rc.d artifactory defaults 95 10

#cat <<EOF >/tmp/binarystore.xml
#<config version="1">
#    <chain template="file-system"/>
#    <provider id="file-system" type="file-system">
#        <fileStoreDir>/mnt/pipeline/artifactory/filestore</fileStoreDir>
#    </provider>
#</config>
#EOF
#sudo cp /tmp/binarystore.xml /opt/artifactory-oss-${artifactory_version}/etc/binarystore.xml

cat <<EOF >/tmp/db.properties
type=mysql
driver=com.mysql.jdbc.Driver
url=jdbc:mysql://localhost:3306/artifactory?characterEncoding=UTF-8&elideSetAutoCommits=true&useSSL=false
username=artifactory
password=artifactory
EOF
sudo mv /tmp/db.properties /opt/artifactory-oss-${artifactory_version}/etc/db.properties

sudo chown artifactory:artifactory /opt/artifactory-oss-${artifactory_version}/etc/db.properties
#sudo chown artifactory:artifactory /opt/artifactory-oss-${artifactory_version}/etc/binarystore.xml

sudo unzip mysql-connector-java-${mysqlconnector_version}.zip mysql-connector-java-${mysqlconnector_version}/mysql-connector-java-${mysqlconnector_version}-bin.jar
sudo cp mysql-connector-java-${mysqlconnector_version}/mysql-connector-java-${mysqlconnector_version}-bin.jar /opt/artifactory-oss-${artifactory_version}/tomcat/lib/
sudo chown artifactory:artifactory /opt/artifactory-oss-${artifactory_version}/tomcat/lib/mysql-connector-java-${mysqlconnector_version}-bin.jar

cat <<EOF >/tmp/my.cnf
[mysqld]

# The maximum size of the binary payload the server can handle
max_allowed_packet=8M

# Tuning
innodb_file_per_table
innodb_buffer_pool_size=1536M
tmp_table_size=512M
max_heap_table_size=512M
innodb_log_file_size=256M
innodb_log_buffer_size=4M
EOF
sudo mv /tmp/my.cnf /etc/mysql/conf.d/mysql.cnf

sudo sed -i 's/JAVA_ARGS=\"\([a-zA-Z\.=-]*\)\"/JAVA_ARGS=\"\1 -Djenkins.install.runSetupWizard=false\"/g' /etc/default/jenkins

sudo service apparmor restart

sudo service mysql restart

sudo service jenkins restart

sudo service sonar restart

sudo service artifactory restart

sleep 20s

curl -L -X GET "http://localhost:8081/artifactory/"

curl -u admin:password -X POST "http://localhost:8081/artifactory/api/import/system" -H "Content-Type: application/json" -d '{"importPath" : "/mnt/pipeline/artifactory/export/20170421.120339", "includeMetadata" : true, "verbose" : false, "failOnError" : true, "failIfEmpty" : true}'

sudo apt-get install -y nginx apache2-utils

sudo cat <<EOF >/tmp/nginx.conf
user www-data www-data;

worker_processes 5;
worker_rlimit_nofile 8192;

events {
  worker_connections 4096;
}

http {
  server {
    listen 80;

    server_name jenkins.nextbreakpoint.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_redirect http://localhost:8080 http://jenkins.${public_hosted_zone_name};
    }
  }
  server {
    listen 80;

    server_name sonarqube.nextbreakpoint.com;

    location / {
        proxy_pass http://localhost:9000;
        proxy_redirect http://localhost:9000 http://sonarqube.${public_hosted_zone_name};
    }
  }
  server {
    listen 80;

    server_name artifactory.nextbreakpoint.com;

    location / {
        proxy_pass http://localhost:8081;
        proxy_redirect http://localhost:8081 http://artifactory.${public_hosted_zone_name};
    }
  }
}
EOF
sudo mv /tmp/nginx.conf /etc/nginx/nginx.conf

sudo service nginx restart

sudo cat <<EOF >/tmp/filebeat.yml
filebeat:
  prospectors:
    -
      paths:
        - /var/log/auth.log
        - /var/log/syslog
        - /var/log/nginx/access.log
        - /var/log/nginx/error.log
        - /var/log/jenkins/jenkins.log
        - /opt/sonarqube-${sonarqube_version}/logs/es.log
        - /opt/sonarqube-${sonarqube_version}/logs/web.log
        - /opt/sonarqube-${sonarqube_version}/logs/sonar.log
        - /opt/sonarqube-${sonarqube_version}/logs/access.log
        - /opt/artifactory-oss-${artifactory_version}/logs/access.log
        - /opt/artifactory-oss-${artifactory_version}/logs/artifactory.log

      input_type: log

      document_type: syslog

  registry_file: /var/lib/filebeat/registry

output:
  logstash:
    hosts: ["logstash.${hosted_zone_name}:5044"]
    bulk_max_size: 1024
    ssl.enabled: false

shipper:

logging:
  files:
    rotateeverybytes: 10485760 # = 10MB
EOF
sudo mv /tmp/filebeat.yml /etc/filebeat/filebeat.yml
sudo chown root.root /etc/filebeat/filebeat.yml
sudo chmod go-w /etc/filebeat/filebeat.yml

sudo update-rc.d filebeat defaults 95 10
sudo service filebeat start

sudo cat <<EOF >/tmp/consul.service
[Unit]
Description=Consul service discovery agent
Requires=network-online.target
After=network.target

[Service]
User=ubuntu
Group=ubuntu
PIDFile=/var/consul/consul.pid
Restart=on-failure
Environment=GOMAXPROCS=2
ExecStartPre=/bin/rm -f /var/consul/consul.pid
ExecStartPre=/usr/local/bin/consul configtest -config-dir=/etc/consul.d
ExecStart=/usr/local/bin/consul agent -pid-file=/var/consul/consul.pid -config-dir=/etc/consul.d -bind="PIPELINE_HOST" -node="pipeline-PIPELINE_HOST" >>/${consul_log_file} 2>&1
ExecReload=/bin/kill -s HUP
KillSignal=SIGINT
TimeoutStopSec=5

[Install]
WantedBy=multi-user.target
EOF
sudo sed -i -e 's/PIPELINE_HOST/'$PIPELINE_HOST'/g' /tmp/consul.service
sudo mv /tmp/consul.service /etc/systemd/system/consul.service

# Setup the consul agent config
sudo cat <<EOF >/tmp/pipeline-consul.json
{
    "datacenter": "terraform",
    "data_dir": "/mnt/consul",
    "log_level": "TRACE",
    "retry_join": ["consul.internal"],
    "enable_script_checks": true,
    "leave_on_terminate": true,
    "services": [{
        "name": "jenkins",
        "tags": [
            "tcp", "jenkins"
        ],
        "port": 8080,
        "checks": [{
            "id": "1",
            "name": "Jenkins TCP",
            "notes": "Use nc to check the tcp port every 60 seconds",
            "script": "nc -zv `ifconfig eth0 | grep 'inet ' | awk '{ print substr($2,6) }'` 8080 >/dev/null 2>&1 ",
            "interval": "60s"
        }],
        "leave_on_terminate": true
    },{
        "name": "artifactory",
        "tags": [
            "tcp", "artifactory"
        ],
        "port": 8081,
        "checks": [{
            "id": "1",
            "name": "Artifactory TCP",
            "notes": "Use nc to check the tcp port every 60 seconds",
            "script": "nc -zv `ifconfig eth0 | grep 'inet ' | awk '{ print substr($2,6) }'` 8081 >/dev/null 2>&1 ",
            "interval": "60s"
        }],
        "leave_on_terminate": true
    },{
        "name": "sonarqube",
        "tags": [
            "tcp", "sonarqube"
        ],
        "port": 9000,
        "checks": [{
            "id": "1",
            "name": "SonarQube TCP",
            "notes": "Use nc to check the tcp port every 60 seconds",
            "script": "nc -zv `ifconfig eth0 | grep 'inet ' | awk '{ print substr($2,6) }'` 9000 >/dev/null 2>&1 ",
            "interval": "60s"
        }],
        "leave_on_terminate": true
    }]
}
EOF
sudo mv /tmp/pipeline-consul.json /etc/consul.d/pipeline.json

sudo service consul start

sudo cat /var/log/jenkins/jenkins.log

echo "Done"
