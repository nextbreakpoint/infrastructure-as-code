#cloud-config
manage_etc_hosts: True
runcmd:
  - sudo mkdir -p /filebeat/config
  - sudo mkdir -p /filebeat/secrets
  - sudo mkdir -p /consul/config
  - sudo mkdir -p /consul/secrets
  - aws s3 cp s3://${bucket_name}/environments/${environment}/filebeat/ca_cert.pem /filebeat/secrets/ca_cert.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/filebeat/client_cert.pem /filebeat/secrets/client_cert.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/filebeat/client_key.pem /filebeat/secrets/client_key.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/consul/ca_cert.pem /consul/secrets/ca_cert.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/consul/server_cert.pem /consul/secrets/server_cert.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/consul/server_key.pem /consul/secrets/server_key.pem
  - sudo usermod -aG docker ubuntu
  - sudo chmod -R ubuntu.ubuntu /consul
  - sudo chmod -R ubuntu.ubuntu /filebeat
  - export HOST_IP_ADDRESS=`ifconfig eth0 | grep "inet " | awk '{ print substr($2,6) }'`
  - sudo -u ubuntu docker run -d --name=consul --restart unless-stopped --net=host -v /consul/config:/consul/config -v /consul/secrets:/consul/secrets consul:latest agent -server=true -ui=true -bind=$HOST_IP_ADDRESS -client=$HOST_IP_ADDRESS -node=consul-$HOST_IP_ADDRESS -retry-join=${consul_hostname} -datacenter=${consul_datacenter} -bootstrap-expect=${consul_bootstrap_expect} -encrypt=${consul_secret}
  - sudo -u ubuntu docker run -d --name=filebeat --restart unless-stopped --net=host -v /filebeat/config/filebeat.yml:/usr/share/filebeat/filebeat.yml -v /filebeat/secrets:/filebeat/secrets docker.elastic.co/beats/filebeat:${filebeat_version}
write_files:
  - path: /consul/config/consul.json
    permissions: '0644'
    content: |
        {
          "ca_file": "/consul/secrets/ca_cert.pem",
          "cert_file": "/consul/secrets/server_cert.pem",
          "key_file": "/consul/secrets/server_key.pem",
          "enable_script_checks": true,
          "leave_on_terminate": true,
          "dns_config": {
            "allow_stale": true,
            "max_stale": "1s",
            "service_ttl": {
              "*": "5s"
            }
          },
          "ports": {
              "https": 8080
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
