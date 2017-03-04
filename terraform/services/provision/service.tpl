#!/bin/bash
set -e

echo "Installing Java 8..."
sudo apt-get install -y software-properties-common
sudo add-apt-repository -y ppa:webupd8team/java
sudo apt-get update

echo "Accept license"
sudo echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
sudo apt-get install -y oracle-java8-installer

sudo apt-get install oracle-java8-set-default

echo "Check installation"
java -version
javac -version

sudo apt-get install -y vim curl wget unzip screen python

echo "Fetching Cloudwatch Agent..."
sudo curl https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py -O

echo "Installing Cloudwatch Agent..."
sudo chmod +x awslogs-agent-setup.py
sudo mv awslogs-agent-setup.py /usr/bin

sudo cat <<EOF >/tmp/cloudwatch.cfg
[general]
state_file = /var/awslogs/state/agent-state

[consul]
file = ${consul_log_file}
log_group_name = ${log_group_name}
log_stream_name = ${log_stream_name}-consul
datetime_format = %b %d %H:%M:%S
EOF

echo "Fetching Consul..."
sudo curl -L -o consul.zip https://releases.hashicorp.com/consul/0.7.5/consul_0.7.5_linux_amd64.zip

echo "Installing Consul..."
sudo unzip consul.zip >/dev/null
sudo chmod +x consul
sudo mv consul /usr/local/bin/consul
sudo mkdir -p /etc/consul.d
sudo mkdir -p /etc/service
sudo mkdir -p /mnt/consul
sudo mkdir -p /var/consul
sudo chmod +rwx /mnt/consul
sudo chmod +rwx /var/consul
sudo chown -R ubuntu:ubuntu /mnt/consul
sudo chown -R ubuntu:ubuntu /var/consul

echo "Fetching Filebeat..."
sudo curl -L -o filebeat.deb https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-5.2.1-amd64.deb

echo "Installing Filebeat..."
sudo apt-get install -y ./filebeat.deb

sudo rm filebeat.deb

#sudo chown filebeat:filebeat -R /usr/share/filebeat

sudo cat <<EOF >/tmp/filebeat.yml
filebeat:
  prospectors:
    -
      paths:
        - /var/log/auth.log
        - /var/log/syslog

      input_type: log
      
      document_type: syslog

  registry_file: /var/lib/filebeat/registry

output:
  logstash:
    bulk_max_size: 1024
    ssl.enabled: false

shipper:

logging:
  files:
    rotateeverybytes: 10485760 # = 10MB
EOF
sudo mv /tmp/filebeat.yml /etc/filebeat/filebeat.yml

#sudo update-rc.d filebeat defaults 95 10
#sudo service filebeat start

echo "Done"
