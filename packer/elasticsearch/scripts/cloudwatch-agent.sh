#!/usr/bin/env bash
set -e

echo "Fetching Cloudwatch Agent..."
cd /tmp
sudo curl https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py -O

echo "Installing Cloudwatch Agent..."
sudo chmod +x awslogs-agent-setup.py
sudo mv awslogs-agent-setup.py /usr/bin

sudo cat <<EOF >/tmp/cloudwatch.cfg
[general]
state_file = /var/awslogs/state/agent-state
EOF

sudo /usr/bin/awslogs-agent-setup.py -n -r ${AWS_REGION} -c /tmp/cloudwatch.cfg
