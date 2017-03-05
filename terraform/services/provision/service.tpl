#!/bin/bash
set -e

sudo cat <<EOF >/tmp/cloudwatch.cfg
[general]
state_file = /var/awslogs/state/agent-state

[consul]
file = ${consul_log_file}
log_group_name = ${log_group_name}
log_stream_name = ${log_stream_name}-consul
datetime_format = %b %d %H:%M:%S
EOF

echo "Fetching Filebeat..."
sudo curl -L -o filebeat.deb https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-5.2.1-amd64.deb

echo "Installing Filebeat..."
sudo apt-get install -y ./filebeat.deb

sudo rm filebeat.deb

#sudo chown filebeat:filebeat -R /usr/share/filebeat

sudo cat <<EOF >/tmp/filebeat.yml
filebeat:
  prospectors:
    -
      paths:
        - /var/log/auth.log
        - /var/log/syslog

      input_type: log
      
      document_type: syslog

  registry_file: /var/lib/filebeat/registry

output:
  logstash:
    bulk_max_size: 1024
    ssl.enabled: false

shipper:

logging:
  files:
    rotateeverybytes: 10485760 # = 10MB
EOF
sudo mv /tmp/filebeat.yml /etc/filebeat/filebeat.yml

#sudo update-rc.d filebeat defaults 95 10
#sudo service filebeat start

echo "Done"
