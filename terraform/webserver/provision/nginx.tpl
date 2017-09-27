#cloud-config
manage_etc_hosts: True
runcmd:
  - export CONSUL_HOST=`ifconfig eth0 | grep "inet " | awk '{ print substr($2,6) }'`
  - sudo docker run -d --name=consul --restart unless-stopped --net=host -v /etc/consul.d:/etc/consul.d consul:latest agent --bind="$CONSUL_HOST" --client="$CONSUL_HOST" --node="consul-$CONSUL_HOST" --retry-join=${consul_hostname} --datacenter=${consul_datacenter}
  - sudo docker run -d --name=nginx --restart unless-stopped --net=host --privileged -v /etc/nginx/nginx.conf:/etc/nginx/nginx.conf -v /var/log/nginx:/var/log/nginx nginx:latest
  - sudo update-rc.d filebeat defaults 95 10
  - aws s3 cp s3://${bucket_name}/environments/${environment}/nginx/server_cert.pem /nginx/server_cert.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/nginx/server_key.pem /nginx/server_key.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/nginx/ca_cert.pem /nginx/ca_cert.pem
  - cat /nginx/server_cert.pem /nginx/ca_cert.pem > /nginx/ca_and_server_cert.pem
  - sudo service filebeat start
  - sudo service dnsmasq restart
  write_files:
    - path: /etc/consul.d/webserver.json
      permissions: '0644'
      content: |
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
    - path: /etc/dnsmasq.d/10-consul
      permissions: '0644'
      content: |
          server=/consul/127.0.0.1#8600
    - path: /etc/filebeat/filebeat.yml
      permissions: '0644'
      content: |
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
    - path: /etc/nginx/nginx.conf
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
              listen 443 ssl;
              server_name consul.${public_hosted_zone_name};

              ssl_certificate     /nginx/ca_and_server_cert.pem;
              ssl_certificate_key /nginx/server_key.pem;
              ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
              ssl_ciphers         HIGH:!aNULL:!MD5;

              location / {
                  resolver 127.0.0.1;
                  set \$$upstream_consul consul.internal;
                  proxy_pass http://\$$upstream_consul:8500\$$request_uri;
                  proxy_redirect http://\$$upstream_consul:8500 https://consul.${public_hosted_zone_name};
                  proxy_set_header Host \$$host;
                  proxy_set_header X-Real-IP \$$remote_addr;
                  proxy_set_header X-Forwarded-For \$$proxy_add_x_forwarded_for;
              }
            }

            server {
              listen 443 ssl;
              server_name kibana.${public_hosted_zone_name};

              ssl_certificate     /nginx/ca_and_server_cert.pem;
              ssl_certificate_key /nginx/server_key.pem;
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

              ssl_certificate     /nginx/ca_and_server_cert.pem;
              ssl_certificate_key /nginx/server_key.pem;
              ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
              ssl_ciphers         HIGH:!aNULL:!MD5;

              location / {
                  resolver 127.0.0.1;
                  set \$$upstream_jenkins jenkins.internal;
                  proxy_pass http://\$$upstream_jenkins:8080\$$request_uri;
                  proxy_redirect http://\$$upstream_jenkins:8080 https://jenkins.${public_hosted_zone_name};
                  proxy_set_header Host \$$host;
                  proxy_set_header X-Real-IP \$$remote_addr;
                  proxy_set_header X-Forwarded-For \$$proxy_add_x_forwarded_for;
              }
            }

            server {
              listen 443 ssl;
              server_name sonarqube.${public_hosted_zone_name};

              ssl_certificate     /nginx/ca_and_server_cert.pem;
              ssl_certificate_key /nginx/server_key.pem;
              ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
              ssl_ciphers         HIGH:!aNULL:!MD5;

              location / {
                  resolver 127.0.0.1;
                  set \$$upstream_sonarqube sonarqube.internal;
                  proxy_pass http://\$$upstream_sonarqube:9000\$$request_uri;
                  proxy_redirect http://\$$upstream_sonarqube:9000 https://sonarqube.${public_hosted_zone_name};
                  proxy_set_header Host \$$host;
                  proxy_set_header X-Real-IP \$$remote_addr;
                  proxy_set_header X-Forwarded-For \$$proxy_add_x_forwarded_for;
              }
            }

            server {
              listen 443 ssl;
              server_name artifactory.${public_hosted_zone_name};

              ssl_certificate     /nginx/ca_and_server_cert.pem;
              ssl_certificate_key /nginx/server_key.pem;
              ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
              ssl_ciphers         HIGH:!aNULL:!MD5;

              location / {
                  resolver 127.0.0.1;
                  set \$$upstream_artifactory artifactory.internal;
                  proxy_pass http://\$$upstream_artifactory:8081\$$request_uri;
                  proxy_redirect http://\$$upstream_artifactory:8081 https://artifactory.${public_hosted_zone_name};
                  proxy_set_header Host \$$host;
                  proxy_set_header X-Real-IP \$$remote_addr;
                  proxy_set_header X-Forwarded-For $$proxy_add_x_forwarded_for;
              }
            }
          }
