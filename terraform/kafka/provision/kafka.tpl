#cloud-config
manage_etc_hosts: True
runcmd:
  - sudo usermod -aG docker ubuntu
  - sudo mkdir -p /filebeat/config
  - sudo mkdir -p /consul/config
  - sudo mkdir -p /kafka/config
  - sudo mkdir -p /kafka/logs
  - sudo chown -R ubuntu:ubuntu /filebeat
  - sudo chown -R ubuntu:ubuntu /consul
  - sudo chown -R ubuntu:ubuntu /kafka
  - export HOST_IP_ADDRESS=`ifconfig eth0 | grep "inet " | awk '{ print substr($2,6) }'`
  - sudo -u ubuntu docker run -d --name=consul --restart unless-stopped --env HOST_IP_ADDRESS=$HOST_IP_ADDRESS --net=host -v /consul/config:/consul/config consul:latest agent -bind=$HOST_IP_ADDRESS -client=$HOST_IP_ADDRESS -node=kafka-$HOST_IP_ADDRESS -retry-join=${consul_hostname} -datacenter=${consul_datacenter}
  - sudo -u ubuntu docker run -d --name=kafka --restart unless-stopped -p 9092:9092 -e BROKER_ID=${broker_id} -e ZK_CONNECT=zookeeper.internal:2181 -e ADVERTISED_HOST=$HOST_IP_ADDRESS -e ADVERTISED_PORT=9092 -e NUM_PARTITIONS=1 -v /kafka/logs:/var/log/supervisor --net=host nextbreakpoint/kafka:${kafka_version}
  - sudo -u ubuntu docker run -d --name=filebeat --restart unless-stopped --net=host -v /filebeat/config/filebeat.yml:/usr/share/filebeat/filebeat.yml -v /kafka/logs:/logs docker.elastic.co/beats/filebeat:${filebeat_version}
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
  - path: /consul/config/kafka.json
    permissions: '0644'
    content: |
        {
            "services": [{
                "name": "kafka",
                "tags": [
                    "tcp", "kafka"
                ],
                "port": 9092,
                "checks": [{
                    "id": "1",
                    "name": "Kafka TCP",
                    "notes": "Use netstat to check the service every 60 seconds",
                    "script": "netstat -tulpn | grep 9092 >/dev/null 2>&1",
                    "interval": "60s"
                } ],
                "leave_on_terminate": true
            }]
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
