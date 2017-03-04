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
file = /var/log/syslog
log_group_name = ${log_group_name}
log_stream_name = ${log_stream_name}-consul
datetime_format = %b %d %H:%M:%S
EOF

echo "Done"
