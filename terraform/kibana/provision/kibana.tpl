#!/bin/bash
set -e

export KIBANA_HOST=`ifconfig eth0 | grep "inet addr" | awk '{ print substr($2,6) }'`
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
ExecStart=/usr/local/bin/consul agent -pid-file=/var/consul/consul.pid -config-dir=/etc/consul.d -bind="KIBANA_HOST" -node="kibana-KIBANA_HOST" >>${consul_log_file} 2>&1
ExecReload=/bin/kill -s HUP 
KillSignal=SIGINT
TimeoutStopSec=5

[Install]
WantedBy=multi-user.target
EOF
sudo sed -i -e 's/KIBANA_HOST/'$KIBANA_HOST'/g' /tmp/consul.service
sudo mv /tmp/consul.service /etc/systemd/system/consul.service

# Setup the consul agent config
sudo cat <<EOF >/tmp/kibana-consul.json
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
        "name": "kibana",
        "tags": [
            "http", "kibana"
        ],
        "port": 5601,
        "checks": [{
            "id": "1",
            "name": "kibana HTTP",
            "notes": "Use curl to check the web service every 10 seconds",
            "script": "curl `ifconfig eth0 | grep 'inet addr' | awk '{ print substr($2,6) }'`:5601 >/dev/null 2>&1",
            "interval": "10s"
        } ],
        "leave_on_terminate": true
    },
    {
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
sudo mv /tmp/kibana-consul.json /etc/consul.d/kibana.json

echo "Fetching Elasticsearch..."
sudo curl -L -o elastic.deb https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.2.1.deb

echo "Installing Elasticsearch..."
sudo apt-get install -y ./elastic.deb

sudo rm elastic.deb

sudo chown elasticsearch:elasticsearch -R /usr/share/elasticsearch
sudo chown elasticsearch:elasticsearch -R /etc/elasticsearch

sudo cat <<EOF >/tmp/elasticsearch.yml
cluster.name: ${es_cluster}
node.master: false
node.data: false
node.ingest: false
node.name: elasticsearch
path.logs: ${elasticsearch_logs_dir}
http.port: 9200
network.host: _ec2:privateIpv4_ 
transport.tcp.port: 9300
discovery.zen.minimum_master_nodes: ${minimum_master_nodes}
cloud.aws.region: ${aws_region}
#discovery.zen.hosts_provider: ec2
#discovery.ec2.tag.name: terraform
#discovery.ec2.availability_zones: ${availability_zones}
discovery.zen.ping.unicast.hosts:
 - ${elasticsearch_node}:9300
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

sudo update-rc.d elasticsearch defaults 95 10
sudo service elasticsearch start

echo "Fetching Kibana..."
sudo curl -L -o kibana.deb https://artifacts.elastic.co/downloads/kibana/kibana-5.2.1-amd64.deb

echo "Installing Kibana..."
sudo apt-get install -y ./kibana.deb

sudo rm kibana.deb

sudo chown kibana:kibana -R /usr/share/kibana

sudo cat <<EOF >/tmp/kibana.yml
server.port: 5601
server.host: "0.0.0.0"
elasticsearch.url: "http://ELASTICSEARCH_HOST:9200"
elasticsearch.preserveHost: true
kibana.index: ".kibana"
#kibana.elasticsearch.username: terraform
#kibana.elasticsearch.password: terraform
kibana.defaultAppId: "discover"
elasticsearch.requestTimeout: 300000
elasticsearch.shardTimeout: 0
elasticsearch.ssl.verify: false
logging.verbose: true
EOF
sudo sed -ie 's/ELASTICSEARCH_HOST/'$ELASTICSEARCH_HOST'/g' /tmp/kibana.yml
sudo mv /tmp/kibana.yml /etc/kibana/kibana.yml

sudo update-rc.d kibana defaults 95 10
sudo service kibana start

echo "Fetching Filebeat..."
sudo curl -L -o filebeat.deb https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-5.2.1-amd64.deb

echo "Installing Filebeat..."
sudo apt-get install -y ./filebeat.deb

sudo rm filebeat.deb

sudo /usr/share/filebeat/scripts/import_dashboards -es http://$ELASTICSEARCH_HOST:9200 -k .kibana

sudo curl -XPUT 'http://'$ELASTICSEARCH_HOST':9200/.kibana/index-pattern/filebeat-*' -d@/tmp/filebeat-index.json

sudo service consul start

#sudo /usr/bin/awslogs-agent-setup.py -n -r ${aws_region} -c /tmp/cloudwatch.cfg

#sudo update-rc.d awslogs defaults 95 10
#sudo service awslogs start

echo "Done"
