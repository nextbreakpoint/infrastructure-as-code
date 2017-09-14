#!/bin/bash
DIR=$(pwd)

export AMIS=$(aws ec2 describe-images --filters Name=tag:stream,Values=terraform,Name=is-public,Values=false --query 'Images[*].{ID:ImageId}' | jq '.[]' | jq -r '.ID')

for ami in $AMIS; do aws ec2 deregister-image --image-id $ami; done;
