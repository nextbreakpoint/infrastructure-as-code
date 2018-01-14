#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/bastion

SUBNET=$(terraform output -json bastion-public-subnet-b-id | jq -r '.value')

echo "Network variables:"
echo "{\"aws_subnet_id\":\"$SUBNET\"}" > $ROOT/config/network_vars.json
cat $ROOT/config/network_vars.json

echo "Creating Base AMI..."
cd $ROOT/packer/base && pk_create
echo "done."

echo "Creating ECS AMI..."
cd $ROOT/packer/ecs && pk_create
echo "done."

echo "Creating OpenVPN AMI..."
cd $ROOT/packer/openvpn && pk_create
echo "done."

aws ec2 describe-images --filters Name=tag:stream,Values=terraform,Name=is-public,Values=false --query 'Images[*].{ID:ImageId}' > $ROOT/images.json

echo "Created images:"
cat $ROOT/images.json
