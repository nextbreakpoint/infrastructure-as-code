#!/bin/bash
set -e

export BROKER_ID=`cat /tmp/brokerid`
export KAFKA_HOST=`ifconfig eth0 | grep "inet " | awk '{ print substr($2,6) }'`

#sudo cat <<EOF >/tmp/cloudwatch.cfg
#[general]
#state_file = /var/awslogs/state/agent-state
#
#[consul]
#file = ${consul_log_file}
#log_group_name = ${log_group_name}
#log_stream_name = ${log_stream_name}-consul
#datetime_format = %b %d %H:%M:%S
#EOF

sudo cat <<EOF >/tmp/consul.service
[Unit]
Description=Consul service discovery agent
Requires=network-online.target
After=network.target

[Service]
User=ubuntu
Group=ubuntu
PIDFile=/var/consul/consul.pid
Restart=on-failure
Environment=GOMAXPROCS=2
ExecStartPre=/bin/rm -f /var/consul/consul.pid
ExecStartPre=/usr/local/bin/consul configtest -config-dir=/etc/consul.d
ExecStart=/usr/local/bin/consul agent -pid-file=/var/consul/consul.pid -config-dir=/etc/consul.d -bind="KAFKA_HOST" -node="kafka-KAFKA_HOST" >>${consul_log_file} 2>&1
ExecReload=/bin/kill -s HUP
KillSignal=SIGINT
TimeoutStopSec=5

[Install]
WantedBy=multi-user.target
EOF
sudo sed -i -e 's/KAFKA_HOST/'$KAFKA_HOST'/g' /tmp/consul.service
sudo mv /tmp/consul.service /etc/systemd/system/consul.service

# Setup the consul agent config
sudo cat <<EOF >/tmp/kafka-consul.json
{
    "datacenter": "terraform",
    "data_dir": "/mnt/consul",
    "log_level": "TRACE",
    "retry_join_ec2": {
      "region": "${aws_region}",
      "tag_key": "stream",
      "tag_value": "terraform"
    },
    "leave_on_terminate": true,
    "services": [{
        "name": "kafka",
        "tags": [
            "telnet", "kafka"
        ],
        "port": 9092,
        "checks": [{
            "id": "1",
            "name": "kafka TCP",
            "notes": "Use netstat to check the service every 10 seconds",
            "script": "netstat -tulpn | grep 9092 >/dev/null 2>&1",
            "interval": "10s"
        } ],
        "leave_on_terminate": true
    }]
}
EOF
sudo mv /tmp/kafka-consul.json /etc/consul.d/kafka.json

sudo cat <<EOF >/tmp/server.properties
# Replication configurations
num.replica.fetchers=4
replica.fetch.max.bytes=1048576
replica.fetch.wait.max.ms=500
replica.high.watermark.checkpoint.interval.ms=5000
replica.socket.timeout.ms=30000
replica.socket.receive.buffer.bytes=65536
replica.lag.time.max.ms=10000
replica.lag.max.messages=4000

controller.socket.timeout.ms=30000
controller.message.queue.size=10

# Log configuration
num.partitions=8
message.max.bytes=1000000
auto.create.topics.enable=true
log.index.interval.bytes=4096
log.index.size.max.bytes=10485760
log.retention.hours=168
log.flush.interval.ms=10000
log.flush.interval.messages=20000
log.flush.scheduler.interval.ms=2000
log.roll.hours=168
log.retention.check.interval.ms=300000
log.segment.bytes=1073741824

# ZK configuration
zk.connection.timeout.ms=6000
zk.sync.time.ms=2000

# Socket server configuration
num.io.threads=8
num.network.threads=8
socket.request.max.bytes=104857600
socket.receive.buffer.bytes=1048576
socket.send.buffer.bytes=1048576
queued.max.requests=16
fetch.purgatory.purge.interval.requests=100
producer.purgatory.purge.interval.requests=100

delete.topic.enable=true

broker.id=BROKER_ID

zookeeper.connect=${zookeeper_nodes}
EOF
sudo sed -i -e 's/BROKER_ID/'$BROKER_ID'/g' /tmp/server.properties
sudo mv /tmp/server.properties /opt/kafka_${scala_version}-${kafka_version}/config/server.properties

sudo sed -i 's/127.0.0.1 .*$/127.0.0.1 localhost '$(hostname)'/g' /etc/hosts

sudo nohup /opt/kafka_${scala_version}-${kafka_version}/bin/kafka-server-start.sh -daemon /opt/kafka_${scala_version}-${kafka_version}/config/server.properties

sudo service consul start

#sudo /usr/bin/awslogs-agent-setup.py -n -r ${aws_region} -c /tmp/cloudwatch.cfg
#sudo update-rc.d awslogs defaults 95 10
#sudo service awslogs start
#sudo systemctl daemon-reload

echo "Done"
