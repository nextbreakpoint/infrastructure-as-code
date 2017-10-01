#cloud-config
manage_etc_hosts: True
runcmd:
  - sudo usermod -aG docker ubuntu
  - sudo mkdir -p /filebeat/config
  - sudo mkdir -p /consul/config
  - sudo mkdir -p /zookeeper/logs
  - sudo mkdir -p /zookeeper/data
  - sudo mkdir -p /zookeeper/config
  - sudo chown -R ubuntu:ubuntu /consul
  - sudo chown -R ubuntu:ubuntu /filebeat
  - sudo chown -R ubuntu:ubuntu /zookeeper
  - export HOST_IP_ADDRESS=`ifconfig eth0 | grep "inet " | awk '{ print substr($2,6) }'`
  - sudo -u ubuntu docker run -d --name=consul --restart unless-stopped --env HOST_IP_ADDRESS=$HOST_IP_ADDRESS --net=host -v /consul/config:/consul/config consul:latest agent -bind=$HOST_IP_ADDRESS -client=$HOST_IP_ADDRESS -node=zookeeper-$HOST_IP_ADDRESS -retry-join=${consul_hostname} -datacenter=${consul_datacenter}
  - sudo -u ubuntu docker run -d --name=zookeeper --restart unless-stopped -p 2181:2181 --net=host -v /zookeeper/config/zoo.cfg:/conf/zoo.cfg -v /zookeeper/config/myid:/var/lib/zookeeper/myid -v /zookeeper/data:/var/lib/zookeeper -v /zookeeper/logs:/var/log zookeeper:latest
  - sudo -u ubuntu docker run -d --name=filebeat --restart unless-stopped --net=host -v /filebeat/config/filebeat.yml:/usr/share/filebeat/filebeat.yml -v /zookeeper/logs:/logs docker.elastic.co/beats/filebeat:${filebeat_version}
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
  - path: /consul/config/zookeeper.json
    permissions: '0644'
    content: |
        {
            "services": [{
                "name": "zookeeper",
                "tags": [
                    "tcp", "zookeeper"
                ],
                "port": 2181,
                "checks": [{
                    "id": "1",
                    "name": "Zookeeper TCP",
                    "notes": "Use nc to check the service every 30 seconds",
                    "script": "echo stat | nc $HOST_IP_ADDRESS 2181 >/dev/null 2>&1",
                    "interval": "30s"
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
          - /logs/zookeeper.log

        output.logstash:
          hosts: ["${logstash_host}:5044"]
  - path: /zookeeper/config/zoo.cfg
    permissions: '0644'
    content: |
        tickTime=2000
        dataDir=/var/lib/zookeeper
        clientPort=2181
        initLimit=5
        syncLimit=2
        server.1=${element(split(",", zookeeper_nodes), 0)}:2888:3888
        server.2=${element(split(",", zookeeper_nodes), 1)}:2888:3888
        server.3=${element(split(",", zookeeper_nodes), 2)}:2888:3888
  - path: /zookeeper/config/myid
    permissions: '0644'
    content: |
        ${zookeeper_id}
