#cloud-config
manage_etc_hosts: True
runcmd:
  - sudo usermod -aG docker ubuntu
  - sudo mkdir -p /filebeat/config
  - sudo mkdir -p /consul/config
  - sudo mkdir -p /nginx/logs
  - sudo mkdir -p /nginx/config
  - sudo mkdir -p /nginx/secrets
  - sudo chmod -R ubuntu.ubuntu /nginx
  - sudo chmod -R ubuntu.ubuntu /consul
  - sudo chmod -R ubuntu.ubuntu /filebeat
  - aws s3 cp s3://${bucket_name}/environments/${environment}/nginx/ca_and_server_cert.pem /nginx/secrets/ca_and_server_cert.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/nginx/server_key.pem /nginx/secrets/server_key.pem
  - export HOST_IP_ADDRESS=`ifconfig eth0 | grep "inet " | awk '{ print substr($2,6) }'`
  - sudo -u ubuntu docker run -d --name=consul --restart unless-stopped --env HOST_IP_ADDRESS=$HOST_IP_ADDRESS --net=host -v /consul/config:/consul/config consul:latest agent -bind=$HOST_IP_ADDRESS -client=$HOST_IP_ADDRESS -node=webserver-$HOST_IP_ADDRESS -retry-join=${consul_hostname} -datacenter=${consul_datacenter}
  - sudo -u ubuntu docker run -d --name=nginx --restart unless-stopped --net=host --privileged -v /nginx/config/nginx.conf:/etc/nginx/nginx.conf -v /nginx/logs:/var/log/nginx -v /nginx/secrets:/nginx/secrets nginx:latest
  - sudo -u ubuntu docker run -d --name=filebeat --restart unless-stopped --net=host -v /filebeat/config/filebeat.yml:/usr/share/filebeat/filebeat.yml -v /nginx/logs:/logs docker.elastic.co/beats/filebeat:${filebeat_version}
write_files:
  - path: /consul/config/consul.json
    permissions: '0644'
    content: |
        {
          "enable_script_checks": true,
          "leave_on_terminate": true,
          "dns_config": {
            "allow_stale": true,
            "max_stale": "1s",
            "service_ttl": {
              "*": "5s"
            }
          }
        }
  - path: /etc/docker/daemon.json
    permissions: '0644'
    content: |
        {
          "log-driver": "json-file",
          "log-opts": {
            "labels": "production"
          }
        }
  - path: /consul/config/webserver.json
    permissions: '0644'
    content: |
        {
            "services": [{
                "name": "webserver-http",
                "tags": [
                    "http", "http"
                ],
                "port": 80,
                "checks": [{
                    "id": "1",
                    "name": "NGINX HTTP",
                    "notes": "Use nc to check the tcp port every 60 seconds",
                    "script": "nc -zv $HOST_IP_ADDRESS 80 >/dev/null 2>&1",
                    "interval": "60s"
                }]
            },{
                "name": "webserver-https",
                "tags": [
                    "tcp", "https"
                ],
                "port": 443,
                "checks": [{
                    "id": "1",
                    "name": "NGINX HTTPS",
                    "notes": "Use nc to check the tcp port every 60 seconds",
                    "script": "nc -zv $HOST_IP_ADDRESS 443 >/dev/null 2>&1",
                    "interval": "60s"
                }]
            }]
        }
  - path: /filebeat/config/filebeat.yml
    permissions: '0644'
    content: |
        logging.level: debug
        filebeat.prospectors:
        - input_type: log
          paths:
          - /logs/*.log

        output.logstash:
          hosts: ["${logstash_host}:5044"]
  - path: /nginx/config/nginx.conf
    permissions: '0644'
    content: |
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
          	return 301 https://$$server_name$$request_uri;
          }

          server {
            listen 80;
            server_name kibana.${public_hosted_zone_name};
          	return 301 https://$$server_name$$request_uri;
          }

          server {
            listen 80;
            server_name jenkins.${public_hosted_zone_name};
          	return 301 https://$$server_name$$request_uri;
          }

          server {
            listen 80;
            server_name sonarqube.${public_hosted_zone_name};
          	return 301 https://$$server_name$$request_uri;
          }

          server {
            listen 80;
            server_name artifactory.${public_hosted_zone_name};
          	return 301 https://$$server_name$$request_uri;
          }

          server {
            listen 80;
            server_name kubernetes.${public_hosted_zone_name};
          	return 301 https://$$server_name$$request_uri;
          }

          server {
            listen 443 ssl;
            server_name consul.${public_hosted_zone_name};

            ssl_certificate     /nginx/secrets/ca_and_server_cert.pem;
            ssl_certificate_key /nginx/secrets/server_key.pem;
            ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
            ssl_ciphers         HIGH:!aNULL:!MD5;

            location / {
                resolver 127.0.0.1;
                set $$upstream_consul consul.internal;
                proxy_pass http://$$upstream_consul:8500$$request_uri;
                proxy_redirect http://$$upstream_consul:8500 https://consul.${public_hosted_zone_name};
                proxy_set_header Host $$host;
                proxy_set_header X-Real-IP $$remote_addr;
                proxy_set_header X-Forwarded-For $$proxy_add_x_forwarded_for;
            }
          }

          server {
            listen 443 ssl;
            server_name kibana.${public_hosted_zone_name};

            ssl_certificate     /nginx/secrets/ca_and_server_cert.pem;
            ssl_certificate_key /nginx/secrets/server_key.pem;
            ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
            ssl_ciphers         HIGH:!aNULL:!MD5;

            location / {
                resolver 127.0.0.1;
                set $$upstream_kibana kibana.internal;
                proxy_pass http://$$upstream_kibana:5601;
                proxy_redirect http://$$upstream_kibana:5601 https://kibana.${public_hosted_zone_name};
                proxy_set_header Host $$host;
                proxy_set_header X-Real-IP $$remote_addr;
                proxy_set_header X-Forwarded-For $$proxy_add_x_forwarded_for;
            }
          }

          server {
            listen 443 ssl;
            server_name jenkins.${public_hosted_zone_name};

            ssl_certificate     /nginx/secrets/ca_and_server_cert.pem;
            ssl_certificate_key /nginx/secrets/server_key.pem;
            ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
            ssl_ciphers         HIGH:!aNULL:!MD5;

            location / {
                resolver 127.0.0.1;
                set $$upstream_jenkins jenkins.internal;
                proxy_pass http://$$upstream_jenkins:8080$$request_uri;
                proxy_redirect http://$$upstream_jenkins:8080 https://jenkins.${public_hosted_zone_name};
                proxy_set_header Host $$host;
                proxy_set_header X-Real-IP $$remote_addr;
                proxy_set_header X-Forwarded-For $$proxy_add_x_forwarded_for;
            }
          }

          server {
            listen 443 ssl;
            server_name sonarqube.${public_hosted_zone_name};

            ssl_certificate     /nginx/secrets/ca_and_server_cert.pem;
            ssl_certificate_key /nginx/secrets/server_key.pem;
            ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
            ssl_ciphers         HIGH:!aNULL:!MD5;

            location / {
                resolver 127.0.0.1;
                set $$upstream_sonarqube sonarqube.internal;
                proxy_pass http://$$upstream_sonarqube:9000$$request_uri;
                proxy_redirect http://$$upstream_sonarqube:9000 https://sonarqube.${public_hosted_zone_name};
                proxy_set_header Host $$host;
                proxy_set_header X-Real-IP $$remote_addr;
                proxy_set_header X-Forwarded-For $$proxy_add_x_forwarded_for;
            }
          }

          server {
            listen 443 ssl;
            server_name artifactory.${public_hosted_zone_name};

            ssl_certificate     /nginx/secrets/ca_and_server_cert.pem;
            ssl_certificate_key /nginx/secrets/server_key.pem;
            ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
            ssl_ciphers         HIGH:!aNULL:!MD5;

            location / {
                resolver 127.0.0.1;
                set $$upstream_artifactory artifactory.internal;
                proxy_pass http://$$upstream_artifactory:8081$$request_uri;
                proxy_redirect http://$$upstream_artifactory:8081 https://artifactory.${public_hosted_zone_name};
                proxy_set_header Host $$host;
                proxy_set_header X-Real-IP $$remote_addr;
                proxy_set_header X-Forwarded-For $$proxy_add_x_forwarded_for;
            }
          }

          server {
            listen 443 ssl;
            server_name kubernetes.${public_hosted_zone_name};

            ssl_certificate     /nginx/secrets/ca_and_server_cert.pem;
            ssl_certificate_key /nginx/secrets/server_key.pem;
            ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
            ssl_ciphers         HIGH:!aNULL:!MD5;

            location / {
                resolver 127.0.0.1;
                set $$upstream_kubernetes kubernetes.internal;
                proxy_pass http://$$upstream_kubernetes:8081$$request_uri;
                proxy_redirect http://$$upstream_kubernetes:8081 https://kubernetes.${public_hosted_zone_name};
                proxy_set_header Host $$host;
                proxy_set_header X-Real-IP $$remote_addr;
                proxy_set_header X-Forwarded-For $$proxy_add_x_forwarded_for;
            }
          }
        }
  - path: /etc/dnsmasq.d/10-consul
    permissions: '0644'
    content: |
        server=/consul/127.0.0.1#8600
