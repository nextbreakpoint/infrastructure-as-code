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
  - sudo mkdir -p /elasticsearch/secrets
  - aws s3 cp s3://${bucket_name}/environments/${environment}/elasticsearch/ca_cert.pem /elasticsearch/secrets/ca_cert.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/filebeat/ca_cert.pem /filebeat/secrets/ca_cert.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/filebeat/filebeat_cert.pem /filebeat/secrets/filebeat_cert.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/filebeat/filebeat_key.pem /filebeat/secrets/filebeat_key.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/logstash/ca_cert.pem /logstash/secrets/ca_cert.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/logstash/logstash_cert.pem /logstash/secrets/logstash_cert.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/logstash/logstash_key.pkcs8 /logstash/secrets/logstash_key.pkcs8
  - aws s3 cp s3://${bucket_name}/environments/${environment}/consul/ca_cert.pem /consul/secrets/ca_cert.pem
  - sudo usermod -aG docker ubuntu
  - sudo chown -R ubuntu:ubuntu /consul
  - sudo chown -R ubuntu:ubuntu /filebeat
  - sudo chown -R ubuntu:ubuntu /logstash
  - export HOST_IP_ADDRESS=`ifconfig eth0 | grep "inet " | awk '{ print substr($2,6) }'`
  - sudo -u ubuntu docker run -d --name=consul --restart unless-stopped --env HOST_IP_ADDRESS=$HOST_IP_ADDRESS --net=host -v /consul/config:/consul/config -v /consul/secrets:/consul/secrets consul:latest agent -bind=$HOST_IP_ADDRESS -client=$HOST_IP_ADDRESS -node=logstash-$HOST_IP_ADDRESS -retry-join=${consul_hostname} -datacenter=${consul_datacenter} -encrypt=${consul_secret}
  - sudo -u ubuntu docker run -d --name=logstash --restart unless-stopped -p 5044:5044 -e LS_JAVA_OPTS="-Dnetworkaddress.cache.ttl=1" --net=host -v /logstash/config/logstash.yml:/usr/share/logstash/config/logstash.yml -v /logstash/pipeline/logstash.conf:/usr/share/logstash/pipeline/logstash.conf -v /logstash/secrets:/usr/share/logstash/config/secrets -v /logstash/logs:/usr/share/logstash/logs docker.elastic.co/logstash/logstash:${logstash_version}
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
  - path: /logstash/pipeline/logstash.conf
    permissions: '0644'
    content: |
        input {
          beats {
            port => 5044
            ssl => true
            ssl_certificate_authorities => ["/usr/share/logstash/config/secrets/ca_cert.pem"]
            ssl_certificate => "/usr/share/logstash/config/secrets/logstash_cert.pem"
            ssl_key => "/usr/share/logstash/config/secrets/logstash_key.pkcs8"
            ssl_verify_mode => "force_peer"
          }
        }
        output {
          elasticsearch {
            hosts => ["https://${elasticsearch_host}:9200"]
            user => "elastic"
            password => "changeme"
            manage_template => false
            index => "%{[@metadata][beat]}-%{+YYYY.MM.dd}"
            document_type => "%{[@metadata][type]}"
            ssl => true
            cacert => "/usr/share/logstash/config/secrets/ca_cert.pem"
          }
        }
  - path: /logstash/config/logstash.yml
    permissions: '0644'
    content: |
        path.config: "/usr/share/logstash/pipeline"
        xpack.monitoring.elasticsearch.url: "https://${elasticsearch_host}:9200"
        xpack.monitoring.elasticsearch.username: "logstash_system"
        xpack.monitoring.elasticsearch.password: "changeme"
        xpack.monitoring.elasticsearch.ssl.ca: "/usr/share/logstash/config/secrets/ca_cert.pem"
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
          ssl.certificate: "/filebeat/secrets/filebeat_cert.pem"
          ssl.key: "/filebeat/secrets/filebeat_key.pem"
