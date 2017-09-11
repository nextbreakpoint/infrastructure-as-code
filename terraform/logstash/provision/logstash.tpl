#!/bin/bash
set -e

export LOGSTASH_HOST=`ifconfig eth0 | grep "inet " | awk '{ print $2 }'`

#sudo cat <<EOF >/tmp/cloudwatch.cfg
#[general]
#state_file = /var/awslogs/state/agent-state
#
#[consul]
#file = ${consul_log_file}
#log_group_name = ${log_group_name}
#log_stream_name = ${log_stream_name}-consul
#datetime_format = %b %d %H:%M:%S
#EOF

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

#sudo update-rc.d logstash defaults 95 10
sudo service logstash start

sudo service consul start

#sudo /usr/bin/awslogs-agent-setup.py -n -r ${aws_region} -c /tmp/cloudwatch.cfg
#sudo update-rc.d awslogs defaults 95 10
#sudo service awslogs start

echo "Done"
