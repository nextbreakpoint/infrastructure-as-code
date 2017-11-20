#cloud-config
manage_etc_hosts: True
runcmd:
  - sudo mkdir -p /filebeat/config
  - sudo mkdir -p /filebeat/secrets
  - sudo mkdir -p /consul/config
  - sudo mkdir -p /consul/secrets
  - aws s3 cp s3://${bucket_name}/environments/${environment}/filebeat/ca_cert.pem /filebeat/secrets/ca_cert.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/filebeat/filebeat_cert.pem /filebeat/secrets/filebeat_cert.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/filebeat/filebeat_key.pem /filebeat/secrets/filebeat_key.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/consul/ca_cert.pem /consul/secrets/ca_cert.pem
  - sudo yum install -y wget dnsmasq bind-utils
  - sudo chown -R ubuntu.ubuntu /consul
  - sudo chown -R ubuntu.ubuntu /filebeat
  - export HOST_IP_ADDRESS=`ifconfig eth0 | grep "inet " | awk '{ print substr($2,6) }'`
  - sudo docker run -d --name=consul --restart unless-stopped --net=host -v /consul/config:/consul/config -v /consul/secrets:/consul/secrets consul:latest agent -bind=$HOST_IP_ADDRESS -client=$HOST_IP_ADDRESS -node=ecs-server-$HOST_IP_ADDRESS -retry-join=${consul_hostname} -datacenter=${consul_datacenter} -encrypt=${consul_secret}
  - sudo docker run -d --name=registrator --restart unless-stopped --net=host --volume=/var/run/docker.sock:/tmp/docker.sock gliderlabs/registrator:latest consul://$HOST_IP_ADDRESS:8500
  - sudo -u ubuntu docker run -d --name=filebeat --restart unless-stopped --net=host -v /filebeat/config/filebeat.yml:/usr/share/filebeat/filebeat.yml -v /filebeat/secrets:/filebeat/secrets docker.elastic.co/beats/filebeat:${filebeat_version}
  - sudo sed -e 's/$HOST_IP_ADDRESS/'$HOST_IP_ADDRESS'/g' /tmp/10-consul > /etc/dnsmasq.d/10-consul
  - sudo service dnsmasq restart
write_files:
  - path: /etc/ecs/ecs.config
    permissions: '0644'
    content: |
        ECS_CLUSTER=${cluster_name}
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
  - path: /tmp/10-consul
    permissions: '0644'
    content: |
        echo server=/consul/$HOST_IP_ADDRESS#8600
