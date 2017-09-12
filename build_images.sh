#!/bin/bash
DIR=$(pwd)

pushd .
export VPC=$(cd terraform/vpc && terraform output -json network-vpc-id | jq -r '.value')
popd

pushd .
export SUBNET=$(cd terraform/vpc && terraform output -json network-private-subnet-a-id | jq -r '.value')
popd

echo "{\"aws_vpc_id\":\"$VPC\",\"aws_subnet_id\":\"$SUBNET\"}" > network_vars.json

cd $DIR/packer && sh build.sh
