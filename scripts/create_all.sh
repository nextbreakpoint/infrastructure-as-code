#!/bin/sh

echo "Creating SSH keys..."
sh scripts/create_keys.sh
echo "done."

echo "Creating VPC, subnets, Route53 zones..."
sh scripts/create_network.sh
echo "done."

echo "Creating stack..."
sh scripts/create_stack.sh
echo "done."
