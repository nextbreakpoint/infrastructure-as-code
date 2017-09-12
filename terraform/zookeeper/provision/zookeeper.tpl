#!/bin/bash
set -e

export ZOOKEEPER_HOST=`ifconfig eth0 | grep "inet " | awk '{ print substr($2,6) }'`

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
ExecStart=/usr/local/bin/consul agent -pid-file=/var/consul/consul.pid -config-dir=/etc/consul.d -bind="ZOOKEEPER_HOST" -node="zookeeper-ZOOKEEPER_HOST" >>${consul_log_file} 2>&1
ExecReload=/bin/kill -s HUP
KillSignal=SIGINT
TimeoutStopSec=5

[Install]
WantedBy=multi-user.target
EOF
sudo sed -i -e 's/ZOOKEEPER_HOST/'$ZOOKEEPER_HOST'/g' /tmp/consul.service
sudo mv /tmp/consul.service /etc/systemd/system/consul.service

# Setup the consul agent config
sudo cat <<EOF >/tmp/zookeeper-consul.json
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
        "name": "zookeeper",
        "tags": [
            "nc", "zookeeper"
        ],
        "port": 2181,
        "checks": [{
            "id": "1",
            "name": "zookeeper TCP",
            "notes": "Use nc to check the service every 10 seconds",
            "script": "echo stat | nc `ifconfig eth0 | grep 'inet ' | awk '{ print substr($2,6) }'` 2181 >/dev/null 2>&1",
            "interval": "10s"
        } ],
        "leave_on_terminate": true
    }]
}
EOF
sudo mv /tmp/zookeeper-consul.json /etc/consul.d/zookeeper.json

cat <<EOF >/tmp/zoo.cfg
tickTime=2000
dataDir=/var/lib/zookeeper
clientPort=2181
initLimit=5
syncLimit=2
server.1=${element(split(",", zookeeper_nodes), 0)}:2888:3888
server.2=${element(split(",", zookeeper_nodes), 1)}:2888:3888
server.3=${element(split(",", zookeeper_nodes), 2)}:2888:3888
EOF
sudo mv /tmp/zoo.cfg /etc/zookeeper/conf/zoo.cfg

sudo update-rc.d zookeeper defaults 95 10
sudo service zookeeper restart

sudo service consul start

#sudo /usr/bin/awslogs-agent-setup.py -n -r ${aws_region} -c /tmp/cloudwatch.cfg
#sudo update-rc.d awslogs defaults 95 10
#sudo service awslogs start
#sudo systemctl daemon-reload

echo "Done"
