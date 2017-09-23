#!/bin/bash
set -e

export WEBSERVER_HOST=`ifconfig eth0 | grep "inet " | awk '{ print substr($2,6) }'`

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

# Configure the consul agent
cat <<EOF >/tmp/consul.json
{
    "addresses": {
        "http": "0.0.0.0"
    },
    "disable_anonymous_signature": true,
    "disable_update_check": true,
    "datacenter": "terraform",
    "data_dir": "/mnt/consul",
    "log_level": "TRACE",
    "retry_join": ["consul.internal"],
    "enable_script_checks": true,
    "leave_on_terminate": true
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
ExecStart=/usr/local/bin/consul agent -pid-file=/var/consul/consul.pid -config-dir=/etc/consul.d -bind="WEBSERVER_HOST" -node="webserver-WEBSERVER_HOST" >>/${consul_log_file} 2>&1
ExecReload=/bin/kill -s HUP
KillSignal=SIGINT
TimeoutStopSec=5

[Install]
WantedBy=multi-user.target
EOF
sudo sed -i -e 's/WEBSERVER_HOST/'$WEBSERVER_HOST'/g' /tmp/consul.service
sudo mv /tmp/consul.service /etc/systemd/system/consul.service

# Configure the webserver healthchecks
sudo cat <<EOF >/tmp/webserver.json
{
    "services": [{
        "name": "webserver-80",
        "tags": [
            "http", "query"
        ],
        "port": 80,
        "checks": [{
            "id": "1",
            "name": "NGINX HTTP",
            "notes": "Use curl to check the web service every 60 seconds",
            "script": "nc -zv `ifconfig eth0 | grep 'inet ' | awk '{ print substr($2,6) }'` 80 >/dev/null 2>&1 ",
            "interval": "60s"
        } ],
        "leave_on_terminate": true
    },{
        "name": "webserver-443",
        "tags": [
            "tcp", "index"
        ],
        "port": 443,
        "checks": [{
            "id": "1",
            "name": "NGINX TCP",
            "notes": "Use nc to check the tcp port every 60 seconds",
            "script": "nc -zv `ifconfig eth0 | grep 'inet ' | awk '{ print substr($2,6) }'` 443 >/dev/null 2>&1 ",
            "interval": "60s"
        }],
        "leave_on_terminate": true
    }]
}
EOF
sudo mv /tmp/webserver.json /etc/consul.d/webserver.json

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
sudo chown root.root /etc/filebeat/filebeat.yml
sudo chmod go-w /etc/filebeat/filebeat.yml

sudo update-rc.d filebeat defaults 95 10
sudo service filebeat start

sudo cat <<EOF >/tmp/nginx.conf
worker_processes 4;
worker_rlimit_nofile 8192;

events {
  worker_connections 4096;
}

user www-data www-data;

http {
  ssl_session_cache     shared:SSL:10m;
  ssl_session_timeout   10m;

  server {
    listen 80;

    server_name consul.${public_hosted_zone_name};

  	return 301 https://\$$server_name\$$request_uri;
  }

  server {
    listen 80;

    server_name kibana.${public_hosted_zone_name};

  	return 301 https://\$$server_name\$$request_uri;
  }

  server {
    listen 80;

    server_name jenkins.${public_hosted_zone_name};

  	return 301 https://\$$server_name\$$request_uri;
  }

  server {
    listen 80;

    server_name sonarqube.${public_hosted_zone_name};

  	return 301 https://\$$server_name\$$request_uri;
  }

  server {
    listen 80;

    server_name artifactory.${public_hosted_zone_name};

  	return 301 https://\$$server_name\$$request_uri;
  }

  server {
    listen 443 ssl;

    server_name consul.${public_hosted_zone_name};

    ssl_certificate     /nginx/nginx.crt;
    ssl_certificate_key /nginx/nginx.key;
    ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    location / {
        resolver 127.0.0.1;
        set \$$upstream_consul consul.internal;
        proxy_pass http://\$$upstream_consul:8500\$$uri;
        proxy_redirect http://\$$upstream_consul:8500 https://consul.${public_hosted_zone_name};
        proxy_set_header Host \$$host;
        proxy_set_header X-Real-IP \$$remote_addr;
        proxy_set_header X-Forwarded-For \$$proxy_add_x_forwarded_for;
    }
  }

  server {
    listen 443 ssl;

    server_name kibana.${public_hosted_zone_name};

    ssl_certificate     /nginx/nginx.crt;
    ssl_certificate_key /nginx/nginx.key;
    ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    location / {
        resolver 127.0.0.1;
        set \$$upstream_kibana kibana.internal;
        proxy_pass http://\$$upstream_kibana:5601;
        proxy_redirect http://\$$upstream_kibana:5601 https://kibana.${public_hosted_zone_name};
        proxy_set_header Host \$$host;
        proxy_set_header X-Real-IP \$$remote_addr;
        proxy_set_header X-Forwarded-For \$$proxy_add_x_forwarded_for;
    }
  }

  server {
    listen 443 ssl;

    server_name jenkins.${public_hosted_zone_name};

    ssl_certificate     /nginx/nginx.crt;
    ssl_certificate_key /nginx/nginx.key;
    ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    location / {
        resolver 127.0.0.1;
        set \$$upstream_jenkins jenkins.internal;
        proxy_pass http://\$$upstream_jenkins:8080\$$uri;
        proxy_redirect http://\$$upstream_jenkins:8080 https://jenkins.${public_hosted_zone_name};
        proxy_set_header Host \$$host;
        proxy_set_header X-Real-IP \$$remote_addr;
        proxy_set_header X-Forwarded-For \$$proxy_add_x_forwarded_for;
    }
  }

  server {
    listen 443 ssl;

    server_name sonarqube.${public_hosted_zone_name};

    ssl_certificate     /nginx/nginx.crt;
    ssl_certificate_key /nginx/nginx.key;
    ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    location / {
        resolver 127.0.0.1;
        set \$$upstream_sonarqube sonarqube.internal;
        proxy_pass http://\$$upstream_sonarqube:9000\$$uri;
        proxy_redirect http://\$$upstream_sonarqube:9000 https://sonarqube.${public_hosted_zone_name};
        proxy_set_header Host \$$host;
        proxy_set_header X-Real-IP \$$remote_addr;
        proxy_set_header X-Forwarded-For \$$proxy_add_x_forwarded_for;
    }
  }

  server {
    listen 443 ssl;

    server_name artifactory.${public_hosted_zone_name};

    ssl_certificate     /nginx/nginx.crt;
    ssl_certificate_key /nginx/nginx.key;
    ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    location / {
        resolver 127.0.0.1;
        set \$$upstream_artifactory artifactory.internal;
        proxy_pass http://\$$upstream_artifactory:8081\$$uri;
        proxy_redirect http://\$$upstream_artifactory:8081 https://artifactory.${public_hosted_zone_name};
        proxy_set_header Host \$$host;
        proxy_set_header X-Real-IP \$$remote_addr;
        proxy_set_header X-Forwarded-For \$$proxy_add_x_forwarded_for;
    }
  }
}
EOF
sudo mv /tmp/nginx.conf /etc/nginx/nginx.conf

sudo cat <<EOF >/tmp/dnsmasq.consul
server=/consul/127.0.0.1#8600
EOF
sudo mv /tmp/dnsmasq.consul /etc/dnsmasq.d/10-consul

aws s3 cp s3://${bucker_name}/environments/${environment}/nginx/nginx.crt /nginx/nginx.crt
aws s3 cp s3://${bucker_name}/environments/${environment}/nginx/nginx.key /nginx/nginx.key

sudo service dnsmasq restart

sudo service nginx restart

sudo service consul start

echo "Done"
