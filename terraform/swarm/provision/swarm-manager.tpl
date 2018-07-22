#cloud-config
manage_etc_hosts: true
manage_resolv_conf: false
runcmd:
  - sudo aws s3 cp s3://${bucket_name}/environments/${environment}/${colour}/swarm/ca_cert.pem /etc/docker/ca_cert.pem
  - sudo aws s3 cp s3://${bucket_name}/environments/${environment}/${colour}/swarm/server_key.pem /etc/docker/server_key.pem
  - sudo aws s3 cp s3://${bucket_name}/environments/${environment}/${colour}/swarm/server_cert.pem /etc/docker/server_cert.pem
  - sudo aws s3 cp s3://${bucket_name}/environments/${environment}/${colour}/swarm/client_key.pem /etc/docker/client_key.pem
  - sudo aws s3 cp s3://${bucket_name}/environments/${environment}/${colour}/swarm/client_cert.pem /etc/docker/client_cert.pem
  - sudo bash -c 'echo \"vm.max_map_count=1048575\" > /etc/sysctl.d/20-docker.conf'
  - sudo bash -c 'echo \"vm.swappiness=1\" > /etc/sysctl.d/20-docker.conf'
  - sudo sysctl -w vm.max_map_count=1048575
  - sudo sysctl -w vm.swappiness=1
  - export HOST_IP_ADDRESS=`ifconfig eth0 | grep "inet " | awk '{ print substr($2,6) }'`
  - sudo hostname > /etc/hostname
  - sudo systemctl daemon-reload
  - sudo service docker restart
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
