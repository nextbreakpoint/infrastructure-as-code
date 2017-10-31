#cloud-config
manage_etc_hosts: True
runcmd:
  - sudo sysctl -w vm.max_map_count=262144
  - sudo usermod -aG docker ubuntu
  - sudo mkdir -p /filebeat/config
  - sudo mkdir -p /filebeat/secrets
  - sudo mkdir -p /consul/config
  - sudo mkdir -p /kibana/config
  - sudo mkdir -p /elasticsearch/config
  - sudo mkdir -p /elasticsearch/data
  - sudo mkdir -p /elasticsearch/logs
  - sudo chmod -R ubuntu.ubuntu /consul
  - sudo chmod -R ubuntu.ubuntu /filebeat
  - sudo chown -R ubuntu:ubuntu /elasticsearch
  - aws s3 cp s3://${bucket_name}/environments/${environment}/filebeat/ca_cert.pem /filebeat/secrets/ca_cert.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/filebeat/client_cert.pem /filebeat/secrets/client_cert.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/filebeat/client_key.pem /filebeat/secrets/client_key.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/consul/ca_cert.pem /consul/secrets/ca_cert.pem
  - export HOST_IP_ADDRESS=`ifconfig eth0 | grep "inet " | awk '{ print substr($2,6) }'`
  - sudo -u ubuntu docker run -d --name=consul --restart unless-stopped --env HOST_IP_ADDRESS=$HOST_IP_ADDRESS --net=host -v /consul/config:/consul/config consul:latest agent -bind=$HOST_IP_ADDRESS -client=$HOST_IP_ADDRESS -node=kibana-$HOST_IP_ADDRESS -retry-join=${consul_hostname} -datacenter=${consul_datacenter} -encrypt=${consul_secret}
  - sudo -u ubuntu docker run -d --name=elasticsearch --restart unless-stopped -p 9200:9200 -p 9300:9300 --ulimit nofile=65536:65536 --ulimit memlock=-1:-1 -e xpack.security.enabled=true -e cluster.name=${cluster_name} -e network.host=0.0.0.0 -e network.publish_host=$HOST_IP_ADDRESS -e network.bind_host=0.0.0.0 -e http.port=9200 -e transport.tcp.port=9300 -e bootstrap.memory_lock=true -e discovery.zen.ping.unicast.hosts=${elasticsearch_nodes} -e discovery.zen.minimum_master_nodes=${minimum_master_nodes} -e ES_JAVA_OPTS="-Xms512m -Xmx512m" -e node.master=false -e node.data=false -e node.ingest=false --net=host -v /elasticsearch/data:/usr/share/elasticsearch/data -v /elasticsearch/logs:/usr/share/elasticsearch/logs docker.elastic.co/elasticsearch/elasticsearch:${elasticsearch_version}
  - sudo -u ubuntu docker run -d --name=kibana --restart unless-stopped -p 5601:5601 -e ELASTICSEARCH_URL=http://elastic:changeme@${elasticsearch_host}:9200 --net=host -v /kibana/config/kibana.yml:/usr/share/kibana/config/kibana. -v /kibana/logs:/usr/share/kibana/logs docker.elastic.co/kibana/kibana:${kibana_version}
  - sudo -u ubuntu docker run -d --name=filebeat --restart unless-stopped --net=host -v /filebeat/config/filebeat.yml:/usr/share/filebeat/filebeat.yml -v /elasticsearch/logs:/logs/elasticsearch -v /kibana/logs:/logs/kibana docker.elastic.co/beats/filebeat:${filebeat_version}
  - sudo curl -XPUT 'http://elastic:changeme@'$HOST_IP_ADDRESS':9200/.kibana/index-pattern/filebeat-*' -d@/filebeat/config/filebeat-index.json
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
  - path: /consul/config/elasticsearch.json
    permissions: '0644'
    content: |
        {
            "services": [{
                "name": "elasticsearch-query",
                "tags": [
                    "http", "query"
                ],
                "port": 9200,
                "checks": [{
                    "id": "1",
                    "name": "Elasticsearch HTTP",
                    "notes": "Use curl to check the web service every 60 seconds",
                    "script": "curl $HOST_IP_ADDRESS:9200 >/dev/null 2>&1",
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
  - path: /consul/config/kibana.json
    permissions: '0644'
    content: |
        {
            "services": [{
                "name": "kibana",
                "tags": [
                    "http", "kibana"
                ],
                "port": 5601,
                "checks": [{
                    "id": "1",
                    "name": "Kibana HTTP",
                    "notes": "Use curl to check the web service every 60 seconds",
                    "script": "curl $HOST_IP_ADDRESS:5601 >/dev/null 2>&1",
                    "interval": "60s"
                }]
            }]
        }
  - path: /kibana/config/kibana.yml
    permissions: '0644'
    content: |
        server.port: 5601
        server.host: "0.0.0.0"
        logging.verbose: false
        kibana.index: ".kibana"
        kibana.defaultAppId: "discover"
  - path: /filebeat/config/filebeat.yml
    permissions: '0644'
    content: |
        filebeat.prospectors:
        - input_type: log
          paths:
          - /logs/kibana/*.log
          - /logs/elasticsearch/*.log

        output.logstash:
          hosts: ["${logstash_host}:5044"]
          ssl.certificate_authorities: ["/filebeat/secrets/ca_cert.pem"]
          ssl.certificate: "/filebeat/secrets/client_cert.pem"
          ssl.key: "/filebeat/secrets/client_key.pem"
  - path: /filebeat/config/filebeat-index.json
    permissions: '0644'
    content: |
        ${filebeat_index}
