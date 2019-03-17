#cloud-config
manage_etc_hosts: true
manage_resolv_conf: false
runcmd:
  - sudo aws s3 cp s3://${bucket_name}/environments/${environment}/${colour}/swarm/ca_cert.pem /etc/docker/ca_cert.pem
  - sudo aws s3 cp s3://${bucket_name}/environments/${environment}/${colour}/swarm/server_key.pem /etc/docker/server_key.pem
  - sudo aws s3 cp s3://${bucket_name}/environments/${environment}/${colour}/swarm/server_cert.pem /etc/docker/server_cert.pem
  - sudo aws s3 cp s3://${bucket_name}/environments/${environment}/${colour}/swarm/client_key.pem /etc/docker/client_key.pem
  - sudo aws s3 cp s3://${bucket_name}/environments/${environment}/${colour}/swarm/client_cert.pem /etc/docker/client_cert.pem
  - sudo bash -c 'echo "vm.max_map_count=1048575" >> /etc/sysctl.conf'
  - sudo bash -c 'echo "vm.swappiness=1" >> /etc/sysctl.conf'
  - sudo sysctl -w vm.max_map_count=1048575
  - sudo sysctl -w vm.swappiness=1
  - export HOST_IP_ADDRESS=`ifconfig eth0 | grep "inet " | awk '{ print substr($2,6) }'`
  - sudo hostname > /etc/hostname
  - sudo systemctl daemon-reload
  - sudo service docker restart
  - sudo sh /update-route53-A.sh
write_files:
  - path: /etc/profile.d/variables
    permissions: '0644'
    content: |
        ENVIRONMENT=${environment}
        COLOUR=${colour}
  - path: /etc/systemd/system/docker.service.d/simple_dockerd.conf
    permissions: '0644'
    content: |
        [Service]
        ExecStart=
        ExecStart=/usr/bin/dockerd
  - path: /etc/docker/daemon.json
    permissions: '0644'
    content: |
        {
            "hosts": ["fd://", "tcp://0.0.0.0:2376", "unix:///var/run/docker.sock"],
            "dns": ["${hosted_zone_dns}", "8.8.8.8", "8.8.4.4"],
            "ipv6": false,
            "tls": true,
            "tlsverify": false,
            "tlscacert": "/etc/docker/ca_cert.pem",
            "tlscert": "/etc/docker/server_cert.pem",
            "tlskey": "/etc/docker/server_key.pem",
            "experimental": true,
            "log-driver": "gelf",
            "log-opts": {
                "gelf-address": "udp://localhost:12201",
                "labels": "service"
            },
            "default-ulimits":
            {
                "nproc": {
                    "Name": "nproc",
                    "Hard": 4096,
                    "Soft": 4096
                },
                "nofile": {
                    "Name": "nofile",
                    "Hard": 65536,
                    "Soft": 65536
                },
                "memlock": {
                    "Name": "memlock",
                    "Hard": -1,
                    "Soft": -1
                }
            }
        }
  - path: /update-route53-A.sh
    permissions: '0644'
    content: |
        #!/bin/sh

        if [ -z "$1" ]; then
            echo "IP not given...trying EC2 metadata...";
            IP=$( curl http://169.254.169.254/latest/meta-data/public-ipv4 )
        else
            IP="$1"
        fi
        echo "IP to update: $IP"

        HOSTED_ZONE_ID=${hosted_zone_id}
        echo "Hosted zone being modified: $HOSTED_ZONE_ID"

        INPUT_JSON=$( cat /update-route53-A.json | sed "s/127\.0\.0\.1/$IP/" )

        # http://docs.aws.amazon.com/cli/latest/reference/route53/change-resource-record-sets.html
        # We want to use the string variable command so put the file contents (batch-changes file) in the following JSON
        INPUT_JSON="{ \"ChangeBatch\": $INPUT_JSON }"

        aws route53 change-resource-record-sets --hosted-zone-id "$HOSTED_ZONE_ID" --cli-input-json "$INPUT_JSON"
  - path: /update-route53-A.json
    permissions: '0644'
    content: |
        {
          "Comment": "Update the A record set",
          "Changes": [
            {
              "Action": "UPSERT",
              "ResourceRecordSet": {
                "Name": "${swarm_ext_dns}",
                "Type": "A",
                "TTL": 300,
                "ResourceRecords": [
                  {
                    "Value": "127.0.0.1"
                  }
                ]
              }
            }
          ]
        }
