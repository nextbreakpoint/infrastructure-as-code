#!/bin/bash
set -e

sudo cat <<EOF >/tmp/cloudwatch.cfg
[general]
state_file = /var/awslogs/state/agent-state

[consul]
file = ${consul_log_file}
log_group_name = ${log_group_name}
log_stream_name = ${log_stream_name}-consul
datetime_format = %b %d %H:%M:%S
EOF

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
        - /var/log/nginx/access.log
        - /var/log/nginx/error.log

      input_type: log
      
      document_type: syslog

  registry_file: /var/lib/filebeat/registry

output:
  logstash:
    hosts: ["${logstash_host}:5044"]
    bulk_max_size: 1024
    ssl.enabled: false

shipper:

logging:
  files:
    rotateeverybytes: 10485760 # = 10MB
EOF
sudo mv /tmp/filebeat.yml /etc/filebeat/filebeat.yml

sudo update-rc.d filebeat defaults 95 10
sudo service filebeat start

sudo cat <<EOF >/tmp/nginx.conf
user www-data www-data;

worker_processes 5;
worker_rlimit_nofile 8192;

events {
  worker_connections 4096;
}

http {
  server {
    listen *:5601;

    location / {
        proxy_pass http://${kibana_host}:5601;
    }
  }
  server {
    listen *:8500;

    location / {
        proxy_pass http://${consul_host}:8500;
    }
  }
}
EOF
sudo mv /tmp/nginx.conf /etc/nginx/nginx.conf

sudo service nginx restart

echo "Done"
