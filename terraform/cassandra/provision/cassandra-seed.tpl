#cloud-config
manage_etc_hosts: True
runcmd:
  - sudo mkdir -p /filebeat/config
  - sudo mkdir -p /filebeat/secrets
  - sudo mkdir -p /consul/config
  - sudo mkdir -p /consul/secrets
  - sudo mkdir -p /cassandra/config
  - sudo mkdir -p /cassandra/data
  - sudo mkdir -p /cassandra/logs
  - aws s3 cp s3://${bucket_name}/environments/${environment}/filebeat/ca_cert.pem /filebeat/secrets/ca_cert.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/filebeat/client_cert.pem /filebeat/secrets/client_cert.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/filebeat/client_key.pem /filebeat/secrets/client_key.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/consul/ca_cert.pem /consul/secrets/ca_cert.pem
  - sudo usermod -aG docker ubuntu
  - sudo chown -R ubuntu:ubuntu /filebeat
  - sudo chown -R ubuntu:ubuntu /consul
  - sudo chown -R ubuntu:ubuntu /cassandra
  - export HOST_IP_ADDRESS=`ifconfig eth0 | grep "inet " | awk '{ print substr($2,6) }'`
  - sudo -u ubuntu docker run -d --name=consul --restart unless-stopped --env HOST_IP_ADDRESS=$HOST_IP_ADDRESS --net=host -v /consul/config:/consul/config -v /consul/secrets:/consul/secrets consul:latest agent -bind=$HOST_IP_ADDRESS -client=$HOST_IP_ADDRESS -node=cassandra-$HOST_IP_ADDRESS -retry-join=${consul_hostname} -datacenter=${consul_datacenter} -encrypt=${consul_secret}
  - sudo -u ubuntu docker run -d --name=cassandra --restart unless-stopped -p 7000:7000 -e CASSANDRA_BROADCAST_ADDRESS=$HOST_IP_ADDRESS -e CASSANDRA_RPC_ADDRESS=$HOST_IP_ADDRESS -e CASSANDRA_LISTEN_ADDRESS=$HOST_IP_ADDRESS -e CASSANDRA_RACK=RACK1 -e CASSANDRA_DC=DC1 --net=host -v /cassandra/data:/var/lib/cassandra -v /cassandra/logs:/var/log/cassandra cassandra:latest
  - sudo -u ubuntu docker run -d --name=filebeat --restart unless-stopped --net=host -v /filebeat/config/filebeat.yml:/usr/share/filebeat/filebeat.yml -v /filebeat/secrets:/filebeat/secrets -v /cassandra/logs:/logs docker.elastic.co/beats/filebeat:${filebeat_version}
  - sleep 60
  - sudo nodetool status
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

        output.logstash:
          hosts: ["${logstash_host}:5044"]
          ssl.certificate_authorities: ["/filebeat/secrets/ca_cert.pem"]
          ssl.certificate: "/filebeat/secrets/client_cert.pem"
          ssl.key: "/filebeat/secrets/client_key.pem"
