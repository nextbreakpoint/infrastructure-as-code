#cloud-config
manage_etc_hosts: True
runcmd:
  - sudo mkdir -p /filebeat/docker
  - sudo mkdir -p /filebeat/config/secrets
  - sudo mkdir -p /consul/config/secrets
  - sudo mkdir -p /kafka/logs
  - aws s3 cp s3://${bucket_name}/environments/${environment}/filebeat/ca_cert.pem /filebeat/config/secrets/ca_cert.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/filebeat/filebeat_cert.pem /filebeat/config/secrets/filebeat_cert.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/filebeat/filebeat_key.pem /filebeat/config/secrets/filebeat_key.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/consul/ca_cert.pem /consul/config/secrets/ca_cert.pem
  - sudo usermod -aG docker ubuntu
  - sudo chown -R ubuntu:ubuntu /filebeat
  - sudo chown -R ubuntu:ubuntu /consul
  - sudo chown -R ubuntu:ubuntu /kafka
  - export HOST_IP_ADDRESS=`ifconfig eth0 | grep "inet " | awk '{ print substr($2,6) }'`
  - sudo -u ubuntu docker run -d --name=consul --restart unless-stopped --net=host -e HOST_IP_ADDRESS=$HOST_IP_ADDRESS -v /consul/config:/consul/config consul:latest agent -bind=$HOST_IP_ADDRESS -client=$HOST_IP_ADDRESS -node=kafka-$HOST_IP_ADDRESS
  - sudo -u ubuntu docker run -d --name=kafka --restart unless-stopped --net=host -p 9092:9092 -e BROKER_ID=${broker_id} -e ZK_CONNECT=zookeeper.service.terraform.consul:2181 -e ADVERTISED_HOST=$HOST_IP_ADDRESS -e ADVERTISED_PORT=9092 -e NUM_PARTITIONS=1 -v /kafka/logs:/var/log nextbreakpoint/kafka:${kafka_version}
  - sudo -u ubuntu docker build -t filebeat:${filebeat_version} /filebeat/docker
  - sudo -u ubuntu docker run -d --name=filebeat --restart unless-stopped --net=host --log-driver json-file -v /filebeat/config/filebeat.yml:/usr/share/filebeat/filebeat.yml -v /filebeat/config/secrets:/filebeat/config/secrets -v /var/log/syslog:/var/log/docker filebeat:${filebeat_version}
  - sudo sed -e 's/$HOST_IP_ADDRESS/'$HOST_IP_ADDRESS'/g' /tmp/10-consul > /etc/dnsmasq.d/10-consul
  - sudo service dnsmasq restart
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
          "retry_join": ["${element(split(",", consul_nodes), 0)}","${element(split(",", consul_nodes), 1)}","${element(split(",", consul_nodes), 2)}"],
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
                }]
            }]
        }
  - path: /filebeat/config/filebeat.yml
    permissions: '0644'
    content: |
        filebeat.prospectors:
        - input_type: log
          paths:
          - /var/log/docker

        output.logstash:
          hosts: ["logstash.service.terraform.consul:5044"]
          ssl.certificate_authorities: ["/filebeat/config/secrets/ca_cert.pem"]
          ssl.certificate: "/filebeat/config/secrets/filebeat_cert.pem"
          ssl.key: "/filebeat/config/secrets/filebeat_key.pem"
  - path: /tmp/10-consul
    permissions: '0644'
    content: |
        server=/consul/$HOST_IP_ADDRESS#8600
