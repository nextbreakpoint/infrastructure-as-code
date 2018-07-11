#!/bin/sh

ENVIRONMENT=$(cat $(pwd)/config/config.json | jq -r ".environment")
COLOUR=$(cat $(pwd)/config/config.json | jq -r ".colour")

IMAGES=`aws ec2 describe-images --filters Name=tag:Environment,Values=${ENVIRONMENT},Name=tag:Colour,Values=${COLOUR},Name=is-public,Values=false --query 'Images[*].{ID:ImageId}' | jq -r '.[] | .ID' | cat`

echo "List of AMIs: [ "$IMAGES" ]"

for IMAGE in $IMAGES; do aws ec2 deregister-image --image-id $IMAGE; done;
