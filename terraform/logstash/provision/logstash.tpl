#cloud-config
manage_etc_hosts: True
runcmd:
  - sudo mkdir -p /filebeat/docker
  - sudo mkdir -p /filebeat/config/secrets
  - sudo mkdir -p /consul/config/secrets
  - sudo mkdir -p /logstash/config/secrets
  - sudo mkdir -p /logstash/pipeline
  - sudo mkdir -p /logstash/logs
  - sudo mkdir -p /elasticsearch/config/secrets
  - sudo mkdir -p /elasticsearch/data
  - sudo mkdir -p /elasticsearch/logs
  - aws s3 cp s3://${bucket_name}/environments/${environment}/logstash/ca_cert.pem /logstash/config/secrets/ca_cert.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/logstash/logstash_cert.pem /logstash/config/secrets/logstash_cert.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/logstash/logstash_key.pem /logstash/config/secrets/logstash_key.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/logstash/logstash_key.pkcs8 /logstash/config/secrets/logstash_key.pkcs8
  - aws s3 cp s3://${bucket_name}/environments/${environment}/filebeat/ca_cert.pem /filebeat/config/secrets/ca_cert.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/filebeat/filebeat_cert.pem /filebeat/config/secrets/filebeat_cert.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/filebeat/filebeat_key.pem /filebeat/config/secrets/filebeat_key.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/consul/ca_cert.pem /consul/config/secrets/ca_cert.pem
  - sudo sysctl -w vm.max_map_count=262144
  - sudo bash -c "echo \"vm.max_map_count=262144\" > /etc/sysctl.d/20-elasticsearch.conf"
  - sudo usermod -aG docker ubuntu
  - sudo chown -R ubuntu:ubuntu /consul
  - sudo chown -R ubuntu:ubuntu /filebeat
  - sudo chown -R ubuntu:ubuntu /logstash
  - sudo chown -R ubuntu:ubuntu /elasticsearch
  - export HOST_IP_ADDRESS=`ifconfig eth0 | grep "inet " | awk '{ print substr($2,6) }'`
  - sudo -u ubuntu docker run -d --name=consul --restart unless-stopped --net=host -e HOST_IP_ADDRESS=$HOST_IP_ADDRESS -v /consul/config:/consul/config consul:latest agent -bind=$HOST_IP_ADDRESS -client=$HOST_IP_ADDRESS -node=logstash-$HOST_IP_ADDRESS
  - sudo -u ubuntu docker run -d --name=elasticsearch --restart unless-stopped --net=host -p 9200:9200 -p 9300:9300 --ulimit nofile=65536:65536 --ulimit memlock=-1:-1 -e ES_JAVA_OPTS="-Xms256m -Xmx256m -Dnetworkaddress.cache.ttl=1" -e network.publish_host=$HOST_IP_ADDRESS -v /elasticsearch/config/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml -v /elasticsearch/data:/usr/share/elasticsearch/data -v /elasticsearch/logs:/usr/share/elasticsearch/logs -v /logstash/config/secrets:/usr/share/elasticsearch/config/secrets docker.elastic.co/elasticsearch/elasticsearch:${elasticsearch_version}
  - sudo -u ubuntu docker run -d --name=logstash --restart unless-stopped --net=host -p 5044:5044 -e LS_JAVA_OPTS="-Dnetworkaddress.cache.ttl=1" -e ELASTICSEARCH_URL=logstash.internal -v /logstash/config/logstash.yml:/usr/share/logstash/config/logstash.yml -v /logstash/pipeline/logstash.conf:/usr/share/logstash/pipeline/logstash.conf -v /logstash/config/secrets:/usr/share/logstash/config/secrets -v /logstash/logs:/usr/share/logstash/logs docker.elastic.co/logstash/logstash:${logstash_version}
  - sudo -u ubuntu docker build -t filebeat:${filebeat_version} /filebeat/docker
  - sudo -u ubuntu docker run -d --name=filebeat --restart unless-stopped --net=host --log-driver json-file -v /filebeat/config/filebeat.yml:/usr/share/filebeat/filebeat.yml -v /filebeat/config/secrets:/filebeat/config/secrets -v /var/log/syslog:/var/log/docker filebeat:${filebeat_version}
write_files:
  - path: /etc/profile.d/variables
    permissions: '0644'
    content: |
        ENVIRONMENT=${environment}
  - path: /consul/config/consul.json
    permissions: '0644'
    content: |
        {
          "ca_file": "/consul/config/secrets/ca_cert.pem",
          "verify_outgoing" : true,
          "enable_script_checks": true,
          "leave_on_terminate": true,
          "encrypt": "${consul_secret}",
          "retry_join": ["${consul_hostname}"],
          "datacenter": "${consul_datacenter}",
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
          "log-driver": "syslog",
          "log-opts": {
            "tag": "Docker/{{.Name}}[{{.ImageName}}]({{.ID}})"
          }
        }
  - path: /filebeat/docker/Dockerfile
    permissions: '0755'
    content: |
        FROM docker.elastic.co/beats/filebeat:${filebeat_version}
        USER root
        RUN useradd -r syslog -u 104
        RUN usermod -aG adm filebeat
        USER filebeat
  - path: /consul/config/elasticsearch.json
    permissions: '0644'
    content: |
        {
            "services": [{
                "name": "elasticsearch-query",
                "tags": [
                    "https", "query"
                ],
                "port": 9200,
                "checks": [{
                    "id": "1",
                    "name": "Elasticsearch HTTP",
                    "notes": "Use curl to check the web service every 60 seconds",
                    "script": "curl --insecure https://$HOST_IP_ADDRESS:9200 >/dev/null 2>&1",
                    "interval": "60s"
                }]
            },{
                "name": "elasticsearch-index",
                "tags": [
                    "tcp", "index"
                ],
                "port": 9300,
                "checks": [{
                    "id": "1",
                    "name": "Elasticsearch TCP",
                    "notes": "Use nc to check the tcp port every 60 seconds",
                    "script": "nc -zv $HOST_IP_ADDRESS 9300 >/dev/null 2>&1",
                    "interval": "60s"
                }]
            }]
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
            hosts => ["https://$${ELASTICSEARCH_URL}:9200"]
            user => "elastic"
            password => "${elasticsearch_password}"
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
        xpack.monitoring.elasticsearch.url: "https://$${ELASTICSEARCH_URL}:9200"
        xpack.monitoring.elasticsearch.username: "logstash_system"
        xpack.monitoring.elasticsearch.password: "${logstash_password}"
        xpack.monitoring.elasticsearch.ssl.ca: "/usr/share/logstash/config/secrets/ca_cert.pem"
  - path: /filebeat/config/filebeat.yml
    permissions: '0644'
    content: |
        filebeat.prospectors:
        - input_type: log
          paths:
          - /var/log/docker

        output.logstash:
          hosts: ["${logstash_host}:5044"]
          ssl.certificate_authorities: ["/filebeat/config/secrets/ca_cert.pem"]
          ssl.certificate: "/filebeat/config/secrets/filebeat_cert.pem"
          ssl.key: "/filebeat/config/secrets/filebeat_key.pem"
  - path: /elasticsearch/config/elasticsearch.yml
    permissions: '0644'
    content: |
        xpack.security.enabled: true
        xpack.security.http.ssl.enabled: true
        xpack.security.transport.ssl.enabled: true
        xpack.ssl.verification_mode: "certificate"
        xpack.ssl.key: "/usr/share/elasticsearch/config/secrets/logstash_key.pem"
        xpack.ssl.certificate: "/usr/share/elasticsearch/config/secrets/logstash_cert.pem"
        xpack.ssl.certificate_authorities: ["/usr/share/elasticsearch/config/secrets/ca_cert.pem"]
        cluster.name: "${cluster_name}"
        node.master: false
        node.ingest: false
        node.data: false
        network.host: "0.0.0.0"
        network.bind_host: "0.0.0.0"
        http.port: 9200
        transport.tcp.port: 9300
        bootstrap.memory_lock: true
        discovery.zen.ping.unicast.hosts: "${elasticsearch_nodes}"
        discovery.zen.minimum_master_nodes: ${minimum_master_nodes}
