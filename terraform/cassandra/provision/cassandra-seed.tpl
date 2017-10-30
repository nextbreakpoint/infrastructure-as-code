#cloud-config
manage_etc_hosts: True
runcmd:
  - sudo usermod -aG docker ubuntu
  - sudo mkdir -p /filebeat/config
  - sudo mkdir -p /consul/config
  - sudo mkdir -p /cassandra/config
  - sudo mkdir -p /cassandra/data
  - sudo mkdir -p /cassandra/logs
  - sudo chown -R ubuntu:ubuntu /filebeat
  - sudo chown -R ubuntu:ubuntu /consul
  - sudo chown -R ubuntu:ubuntu /cassandra
  - export HOST_IP_ADDRESS=`ifconfig eth0 | grep "inet " | awk '{ print substr($2,6) }'`
  - sudo -u ubuntu docker run -d --name=consul --restart unless-stopped --env HOST_IP_ADDRESS=$HOST_IP_ADDRESS --net=host -v /consul/config:/consul/config consul:latest agent -bind=$HOST_IP_ADDRESS -client=$HOST_IP_ADDRESS -node=cassandra-$HOST_IP_ADDRESS -retry-join=${consul_hostname} -datacenter=${consul_datacenter}
  - sudo -u ubuntu docker run -d --name=cassandra --restart unless-stopped -p 7000:7000 -e CASSANDRA_BROADCAST_ADDRESS=$HOST_IP_ADDRESS -e CASSANDRA_RPC_ADDRESS=$HOST_IP_ADDRESS -e CASSANDRA_LISTEN_ADDRESS=$HOST_IP_ADDRESS -e CASSANDRA_RACK=RACK1 -e CASSANDRA_DC=DC1 --net=host -v /cassandra/data:/var/lib/cassandra -v /cassandra/logs:/var/log/cassandra cassandra:latest
  - sudo -u ubuntu docker run -d --name=filebeat --restart unless-stopped --net=host -v /filebeat/config/filebeat.yml:/usr/share/filebeat/filebeat.yml -v /cassandra/logs:/logs -v /var/log/syslog:/logs/syslog docker.elastic.co/beats/filebeat:${filebeat_version}
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
          "log-driver": "syslog",
          "log-opts": {
            "tag": "docker"
          }
        }
  - path: /consul/config/cassandra.json
    permissions: '0644'
    content: |
        {
            "services": [{
                "name": "cassandra",
                "tags": [
                    "tcp", "cassandra"
                ],
                "port": 7000,
                "checks": [{
                    "id": "1",
                    "name": "Cassandra TCP",
                    "notes": "Use nc to check the service every 60 seconds",
                    "script": "nc -zv $HOST_IP_ADDRESS 7000 >/dev/null 2>&1",
                    "interval": "60s"
                }]
            }]
        }
  - path: /filebeat/config/filebeat.yml
    permissions: '0644'
    content: |
        filebeat.prospectors:
        - input_type: log
          paths:
          - /logs/*.log
            /logs/syslog

        output.logstash:
          hosts: ["${logstash_host}:5044"]
