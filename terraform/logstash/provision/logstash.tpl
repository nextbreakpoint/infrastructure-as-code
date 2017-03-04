#!/bin/bash
set -e

export LOGSTASH_HOST=`ifconfig eth0 | grep "inet addr" | awk '{ print substr($2,6) }'`

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
ExecStart=/usr/local/bin/consul agent -pid-file=/var/consul/consul.pid -config-dir=/etc/consul.d -bind="LOGSTASH_HOST" -node="logstash-LOGSTASH_HOST" >>${consul_log_file} 2>&1
ExecReload=/bin/kill -s HUP 
KillSignal=SIGINT
TimeoutStopSec=5

[Install]
WantedBy=multi-user.target
EOF
sudo sed -i -e 's/LOGSTASH_HOST/'$LOGSTASH_HOST'/g' /tmp/consul.service
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
        "name": "logstash",
        "tags": [
            "tcp", "logstash"
        ],
        "port": 5044,
        "checks": [{
            "id": "1",
            "name": "Logstash TCP",
            "notes": "Use nc to check the tcp port every 10 seconds",
            "script": "nc -zv `ifconfig eth0 | grep 'inet addr' | awk '{ print substr($2,6) }'` 5044 >/dev/null 2>&1 ",
            "interval": "10s"
        }],
        "leave_on_terminate": true
    }]
}
EOF
sudo mv /tmp/kibana-consul.json /etc/consul.d/kibana.json

echo "Fetching Logstash..."
sudo curl -L -o logstash.deb https://artifacts.elastic.co/downloads/logstash/logstash-5.2.1.deb

echo "Installing Logstash..."
sudo apt-get install -y ./logstash.deb

sudo rm logstash.deb

sudo chown logstash:logstash -R /usr/share/logstash

sudo cat <<EOF >/tmp/logstash.yml
path.data: /var/lib/logstash
path.config: /etc/logstash/conf.d
path.logs: /var/log/logstash
http.host: "LOGSTASH_HOST"
EOF
sudo sed -ie 's/LOGSTASH_HOST/'$LOGSTASH_HOST'/g' /tmp/logstash.yml
sudo mv /tmp/logstash.yml /etc/logstash/logstash.yml 

sudo cat <<EOF >/tmp/02-beats-input.conf
input {
  beats {
    port => 5044
    host => "LOGSTASH_HOST"
    ssl => false
  }
}
EOF
sudo sed -ie 's/LOGSTASH_HOST/'$LOGSTASH_HOST'/g' /tmp/02-beats-input.conf
sudo mv /tmp/02-beats-input.conf /etc/logstash/conf.d/02-beats-input.conf

sudo cat <<EOF >/tmp/10-syslog-filter.conf
filter {
  if [type] == "syslog" {
    grok {
      match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:syslog_message}" }
      add_field => [ "received_at", "%{@timestamp}" ]
      add_field => [ "received_from", "%{host}" ]
    }
    syslog_pri { }
    date {
      match => [ "syslog_timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
    }
  }
}
EOF
sudo mv /tmp/10-syslog-filter.conf /etc/logstash/conf.d/10-syslog-filter.conf 

sudo cat <<EOF >/tmp/30-elasticsearch-output.conf
output {
  elasticsearch {
    hosts => ["${elasticsearch_host}:9200"]
    sniffing => true
    manage_template => false
    index => "%{[@metadata][beat]}-%{+YYYY.MM.dd}"
    document_type => "%{[@metadata][type]}"
  }
}
EOF
sudo mv /tmp/30-elasticsearch-output.conf /etc/logstash/conf.d/30-elasticsearch-output.conf 

sudo /usr/share/logstash/bin/logstash-plugin install logstash-input-beats

#sudo update-rc.d logstash defaults 95 10
sudo service logstash start

sudo service consul start

#sudo /usr/bin/awslogs-agent-setup.py -n -r ${aws_region} -c /tmp/cloudwatch.cfg

#sudo update-rc.d awslogs defaults 95 10
#sudo service awslogs start

echo "Done"
