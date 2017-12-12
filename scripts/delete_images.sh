#!/bin/sh

IMAGES=`aws ec2 describe-images --filters Name=tag:stream,Values=terraform,Name=is-public,Values=false --query 'Images[*].{ID:ImageId}' | jq -r '.[] | .ID' | cat`

echo "List of AMIs: [ "$IMAGES" ]"

for IMAGE in $IMAGES; do aws ec2 deregister-image --image-id $IMAGE; done;
