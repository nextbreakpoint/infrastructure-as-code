#!/bin/sh

echo "Generating certificates..."
sh scripts/generate_certificates.sh
echo "done."

echo "Copying certificates..."
sh scripts/copy_certificates.sh
echo "done."

echo "Generating SSH keys..."
sh scripts/generate_keys.sh
echo "done."

echo "Creating SSH keys..."
sh scripts/create_keys.sh
echo "done."

echo "Creating VPC, subnets, Route53 zones..."
sh scripts/create_network.sh
echo "done."

echo "Building AMI images..."
sh scripts/build_images.sh
echo "done."

echo "Configuring Consul..."
sh scripts/configure_consul.sh
echo "done."

echo "Creating stack..."
sh scripts/create_stack.sh
echo "done."
