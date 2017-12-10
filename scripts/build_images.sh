#!/bin/sh

. $ROOT/bash_aliases

export DIR=$ROOT

cd $ROOT/terraform/vpc

export VPC=$(terraform output -json network-vpc-id | jq -r '.value')
export SUBNET=$(terraform output -json network-private-subnet-a-id | jq -r '.value')

echo "Network variables:"
echo "{\"aws_vpc_id\":\"$VPC\",\"aws_subnet_id\":\"$SUBNET\"}" > $ROOT/config/network_vars.json
cat $ROOT/config/network_vars.json

echo "Creating Base AMI..."
cd $DIR/packer/base && pk_create
echo "done."

echo "Creating ECS AMI..."
cd $DIR/packer/ecs && pk_create
echo "done."

echo "Created images:"
aws ec2 describe-images --filters Name=tag:stream,Values=terraform,Name=is-public,Values=false --query 'Images[*].{ID:ImageId}'
