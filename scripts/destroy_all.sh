#!/bin/sh

echo "Destroying ELB..."
sh scripts/destroy_elb.sh
echo "done."

echo "Destroying Stack..."
sh scripts/destroy_stack.sh
echo "done."

echo "Destroying Subnets..."
sh scripts/destroy_network.sh
echo "done."

echo "Destroying VPCs..."
sh scripts/destroy_vpc.sh
echo "done."

echo "Destroying SSH keys..."
sh scripts/destroy_keys.sh
echo "done."
