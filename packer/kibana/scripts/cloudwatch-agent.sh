#!/usr/bin/env bash

set -e

echo "Fetching Cloudwatch Agent..."
cd /tmp
curl https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py -O

echo "Installing Cloudwatch Agent..."
chmod +x awslogs-agent-setup.py
sudo mv awslogs-agent-setup.py /usr/bin