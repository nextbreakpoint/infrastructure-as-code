#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/bastion

SUBNET=$(terraform output -json bastion-public-subnet-a-id | jq -r '.value')

ENVIRONMENT=$(cat $ROOT/config/config.json | jq -r ".environment")
COLOUR=$(cat $ROOT/config/config.json | jq -r ".colour")

echo "Network variables:"
echo "{\"aws_subnet_id\":\"$SUBNET\"}" > $ROOT/config/bastion.json
cat $ROOT/config/bastion.json

echo "Creating Docker AMI..."
cd $ROOT/packer/docker && pk_create
echo "done."

echo "Creating OpenVPN AMI..."
cd $ROOT/packer/openvpn && pk_create
echo "done."

aws ec2 describe-images --filters Name=tag:Environment,Values=${ENVIRONMENT},Name=tag:Colour,Values=${COLOUR},Name=is-public,Values=false --query 'Images[*].{ID:ImageId}' > $ROOT/images.json

echo "Created images:"
cat $ROOT/images.json
