#!/bin/sh

. $ROOT/bash_aliases

ENVIRONMENT=$(cat $ROOT/config/main.json | jq -r ".environment")
COLOUR=$(cat $ROOT/config/main.json | jq -r ".colour")

aws ec2 describe-images --filters Name=tag:Environment,Values=${ENVIRONMENT},Name=tag:Colour,Values=${COLOUR},Name=is-public,Values=false --query 'Images[*].{ID:ImageId}'
