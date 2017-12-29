#!/bin/sh

echo "Destroying ELB..."
sh scripts/destroy_elb.sh
echo "done."

echo "Destroying Stack..."
sh scripts/destroy_stack.sh
echo "done."

echo "Destroying OpenVPN..."
sh scripts/destroy_openvpn.sh
echo "done."

echo "Destroying Subnets..."
sh scripts/destroy_network.sh
echo "done."

echo "Destroying Zones..."
sh scripts/destroy_zones.sh
echo "done."
