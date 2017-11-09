#cloud-config
manage_etc_hosts: True
runcmd:
  - sudo mkdir -p /filebeat/config
  - sudo mkdir -p /filebeat/secrets
  - sudo mkdir -p /consul/config
  - sudo mkdir -p /consul/secrets
  - sudo mkdir -p /logstash/logs
  - sudo mkdir -p /logstash/config
  - sudo mkdir -p /logstash/secrets
  - sudo mkdir -p /logstash/pipeline
  - aws s3 cp s3://${bucket_name}/environments/${environment}/filebeat/ca_cert.pem /filebeat/secrets/ca_cert.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/filebeat/client_cert.pem /filebeat/secrets/client_cert.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/filebeat/client_key.pem /filebeat/secrets/client_key.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/logstash/ca_cert.pem /logstash/secrets/ca_cert.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/logstash/server_cert.pem /logstash/secrets/server_cert.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/logstash/server_key.pkcs8 /logstash/secrets/server_key.pkcs8
  - aws s3 cp s3://${bucket_name}/environments/${environment}/consul/ca_cert.pem /consul/secrets/ca_cert.pem
  - sudo usermod -aG docker ubuntu
  - sudo chown -R ubuntu:ubuntu /consul
  - sudo chown -R ubuntu:ubuntu /filebeat
  - sudo chown -R ubuntu:ubuntu /logstash
  - export HOST_IP_ADDRESS=`ifconfig eth0 | grep "inet " | awk '{ print substr($2,6) }'`
  - sudo -u ubuntu docker run -d --name=consul --restart unless-stopped --env HOST_IP_ADDRESS=$HOST_IP_ADDRESS --net=host -v /consul/config:/consul/config -v /consul/secrets:/consul/secrets consul:latest agent -bind=$HOST_IP_ADDRESS -client=$HOST_IP_ADDRESS -node=logstash-$HOST_IP_ADDRESS -retry-join=${consul_hostname} -datacenter=${consul_datacenter} -encrypt=${consul_secret}
  - sudo -u ubuntu docker run -d --name=logstash --restart unless-stopped -p 5044:5044 -e xpack.monitoring.elasticsearch.url=http://${elasticsearch_host}:9200 -e xpack.monitoring.elasticsearch.username=elastic -e xpack.monitoring.elasticsearch.password=changeme --net=host -v /logstash/pipeline:/usr/share/logstash/pipeline -v /logstash/secrets:/logstash/secrets -v /logstash/logs:/usr/share/logstash/logs docker.elastic.co/logstash/logstash:${logstash_version}
  - sudo -u ubuntu docker run -d --name=filebeat --restart unless-stopped --net=host -v /filebeat/config/filebeat.yml:/usr/share/filebeat/filebeat.yml -v /filebeat/secrets:/filebeat/secrets -v /logstash/logs:/logs docker.elastic.co/beats/filebeat:${filebeat_version}
write_files:
  - path: /consul/config/consul.json
    permissions: '0644'
    content: |
        {
          "ca_file": "/consul/secrets/ca_cert.pem",
          "verify_outgoing" : true,
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
  - path: /consul/config/logstash.json
    permissions: '0644'
    content: |
        {
            "services": [{
                "name": "logstash",
                "tags": [
                    "tcp", "logstash"
                ],
                "port": 5044,
                "checks": [{
                    "id": "1",
                    "name": "Logstash TCP",
                    "notes": "Use nc to check the tcp port every 60 seconds",
                    "script": "nc -zv $HOST_IP_ADDRESS 5044 >/dev/null 2>&1",
                    "interval": "60s"
                }]
            }]
        }
  - path: /logstash/pipeline/pipeline.conf
    permissions: '0644'
    content: |
        input {
          beats {
            port => 5044
            ssl => true
            ssl_certificate_authorities => ["/logstash/secrets/ca_cert.pem"]
            ssl_certificate => "/logstash/secrets/server_cert.pem"
            ssl_key => "/logstash/secrets/server_key.pem"
            ssl_verify_mode => "force_peer"
          }
        }
        output {
          elasticsearch {
            hosts => ["http://${elasticsearch_host}:9200"]
            user => elastic
            password => changeme
            manage_template => false
            index => "%{[@metadata][beat]}-%{+YYYY.MM.dd}"
            document_type => "%{[@metadata][type]}"
          }
        }
  - path: /filebeat/config/filebeat.yml
    permissions: '0644'
    content: |
        filebeat.prospectors:
        - input_type: log
          paths:
          - /logs/*.log

        output.logstash:
          hosts: ["${logstash_host}:5044"]
          ssl.certificate_authorities: ["/filebeat/secrets/ca_cert.pem"]
          ssl.certificate: "/filebeat/secrets/client_cert.pem"
          ssl.key: "/filebeat/secrets/client_key.pkcs8"
