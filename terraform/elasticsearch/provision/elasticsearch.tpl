#!/bin/bash
set -e

export ELASTICSEARCH_HOST=`ifconfig eth0 | grep "inet addr" | awk '{ print substr($2,6) }'`

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

echo "Fetching Elasticsearch..."
sudo curl -L -o elastic.deb https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.2.1.deb

echo "Installing Elasticsearch..."
sudo apt-get install -y ./elastic.deb

sudo rm elastic.deb

sudo chown elasticsearch:elasticsearch -R /usr/share/elasticsearch
sudo chown elasticsearch:elasticsearch -R /etc/elasticsearch

# Configure the consul agent
cat <<EOF >/tmp/consul.json
{
    "addresses"                   : {
        "http" : "0.0.0.0"
    },
    "disable_anonymous_signature" : true,
    "disable_update_check"        : true,
    "data_dir"                    : "/mnt/consul/data"
}
EOF
sudo mv /tmp/consul.json /etc/consul.d/consul.json

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
ExecStart=/usr/local/bin/consul agent -pid-file=/var/consul/consul.pid -config-dir=/etc/consul.d -bind="ELASTICSEARCH_HOST" -node="elasticsearch-ELASTICSEARCH_HOST" >>/${consul_log_file} 2>&1
ExecReload=/bin/kill -s HUP 
KillSignal=SIGINT
TimeoutStopSec=5

[Install]
WantedBy=multi-user.target
EOF
sudo sed -i -e 's/ELASTICSEARCH_HOST/'$ELASTICSEARCH_HOST'/g' /tmp/consul.service
sudo mv /tmp/consul.service /etc/systemd/system/consul.service

# Setup the consul agent config
sudo cat <<EOF >/tmp/elasticsearch-consul.json
{
    "datacenter": "terraform",
    "data_dir": "/mnt/consul",
    "log_level": "TRACE",
    "retry_join_ec2": {
      "region": "${aws_region}",
      "tag_key": "stream",
      "tag_value": "terraform"
    },
    "leave_on_terminate": true,
    "services": [{
        "name": "elasticsearch-9200",
        "tags": [
            "http", "query"
        ],
        "port": 9200,
        "checks": [{
            "id": "1",
            "name": "Elasticsearch HTTP",
            "notes": "Use curl to check the web service every 10 seconds",
            "script": "curl `ifconfig eth0 | grep 'inet addr' | awk '{ print substr($2,6) }'`:9200 >/dev/null 2>&1",
            "interval": "10s"
        } ],
        "leave_on_terminate": true
    },
    {
        "name": "elasticsearch-9300",
        "tags": [
            "tcp", "index"
        ],
        "port": 9300,
        "checks": [{
            "id": "1",
            "name": "Elasticsearch TCP",
            "notes": "Use nc to check the tcp port every 10 seconds",
            "script": "nc -zv `ifconfig eth0 | grep 'inet addr' | awk '{ print substr($2,6) }'` 9300 >/dev/null 2>&1 ",
            "interval": "10s"
        }],
        "leave_on_terminate": true
    }]
}
EOF
sudo mv /tmp/elasticsearch-consul.json /etc/consul.d/elasticsearch.json

sudo cat <<EOF >/tmp/elasticsearch.yml
cluster.name: ${es_cluster}
node.name: elasticsearch
path.data: ${elasticsearch_data_dir}
path.logs: ${elasticsearch_logs_dir}
network.host: _ec2:privateIpv4_
http.port: 9200
transport.tcp.port: 9300
discovery.type: ec2
discovery.ec2.groups: ${security_groups}
discovery.zen.minimum_master_nodes: ${minimum_master_nodes}
cloud.aws.region: ${aws_region}
discovery.ec2.availability_zones: ${availability_zones}
EOF
sudo mv /tmp/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml

sudo mkdir -p ${elasticsearch_data_dir}
sudo mkdir -p ${elasticsearch_logs_dir}

#sudo mkfs -t ext4 ${volume_name}
#sudo mount ${volume_name} ${elasticsearch_data_dir}
#sudo echo "${volume_name} ${elasticsearch_data_dir} ext4 defaults,nofail 0 2" >> /etc/fstab

sudo chown -R elasticsearch:elasticsearch ${elasticsearch_data_dir}
sudo chown -R elasticsearch:elasticsearch ${elasticsearch_logs_dir}

sudo /usr/share/elasticsearch/bin/elasticsearch-plugin install --batch discovery-ec2

echo "Running Elasticsearch..."

#sudo echo "elasticsearch soft nofile 128000" >> /etc/security/limits.conf
#sudo echo "elasticsearch hard nofile 128000" >> /etc/security/limits.conf
#sudo echo "root soft nofile 128000" >> /etc/security/limits.conf
#sudo echo "root hard nofile 128000" >> /etc/security/limits.conf
#sudo echo "fs.file-max = 500000" >> /etc/sysctl.conf

sudo update-rc.d elasticsearch defaults 95 10
sudo service elasticsearch start

sudo service consul start

#sudo /usr/bin/awslogs-agent-setup.py -n -r ${aws_region} -c /tmp/cloudwatch.cfg

#sudo update-rc.d awslogs defaults 95 10
#sudo service awslogs start

echo "Done"
