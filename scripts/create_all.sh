#!/bin/sh

echo "Creating Zones..."
sh scripts/create_zones.sh
echo "done."

echo "Creating Subnets..."
sh scripts/create_network.sh
echo "done."

echo "Creating OpenVPN..."
sh scripts/create_openvpn.sh
echo "done."

echo "Creating Stack..."
sh scripts/create_stack.sh
echo "done."

echo "Creating ELB..."
sh scripts/create_elb.sh
echo "done."
