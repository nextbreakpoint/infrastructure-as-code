#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/bastion

# BASTION_SUBNET variable is required by pk_create alias
BASTION_SUBNET=$(terraform output -json bastion-public-subnet-a-id | jq -r '.value')

ENVIRONMENT=$(cat $ROOT/config/main.json | jq -r ".environment")
COLOUR=$(cat $ROOT/config/main.json | jq -r ".colour")

echo "Using subnet $BASTION_SUBNET"

echo "Creating Docker AMI..."

cd $ROOT/packer/docker && pk_create

if [ $? -ne 0 ]; then
    exit 1
fi

echo "done."

echo "Creating OpenVPN AMI..."

cd $ROOT/packer/openvpn && pk_create

if [ $? -ne 0 ]; then
    exit 1
fi

echo "done."
