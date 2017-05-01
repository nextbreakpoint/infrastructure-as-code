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
    listen 80;

    server_name consul.nextbreakpoint.com;

    location / {
        proxy_pass http://${consul_host}:8500;
        proxy_redirect http://${consul_host}:8500 http://consul.nextbreakpoint.com;
    }
  }
  server {
    listen 80;

    server_name kibana.nextbreakpoint.com;

    location / {
        proxy_pass http://${kibana_host}:5601;
        proxy_redirect http://${kibana_host}:5601 http://kibana.nextbreakpoint.com;
    }
  }
  server {
    listen 80;

    server_name jenkins.nextbreakpoint.com;

    location / {
        proxy_pass http://${jenkins_host}:8080;
        proxy_redirect http://${jenkins_host}:8080 http://jenkins.nextbreakpoint.com;
    }
  }
  server {
    listen 80;

    server_name sonarqube.nextbreakpoint.com;

    location / {
        proxy_pass http://${sonarqube_host}:9000;
        proxy_redirect http://${sonarqube_host}:9000 http://sonarqube.nextbreakpoint.com;
    }
  }
  server {
    listen 80;

    server_name artifactory.nextbreakpoint.com;

    location / {
        proxy_pass http://${artifactory_host}:8081;
        proxy_redirect http://${artifactory_host}:8081 http://artifactory.nextbreakpoint.com;
    }
  }
}
EOF
sudo mv /tmp/nginx.conf /etc/nginx/nginx.conf

sudo service nginx restart

echo "Done"
