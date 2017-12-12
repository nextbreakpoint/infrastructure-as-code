#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/vpc

VPC=$(terraform output -json network-vpc-id | jq -r '.value')
SUBNET=$(terraform output -json network-private-subnet-a-id | jq -r '.value')

echo "Network variables:"
echo "{\"aws_vpc_id\":\"$VPC\",\"aws_subnet_id\":\"$SUBNET\"}" > $ROOT/config/network_vars.json
cat $ROOT/config/network_vars.json

echo "Creating Base AMI..."
cd $ROOT/packer/base && pk_create
echo "done."

echo "Creating ECS AMI..."
cd $ROOT/packer/ecs && pk_create
echo "done."

aws ec2 describe-images --filters Name=tag:stream,Values=terraform,Name=is-public,Values=false --query 'Images[*].{ID:ImageId}' > images.json

echo "Created images:"
cat images.json
