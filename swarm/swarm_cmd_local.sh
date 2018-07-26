#!/bin/sh

export ENVIRONMENT=$(cat $(pwd)/../config/config.json | jq -r ".environment")
export COLOUR=$(cat $(pwd)/../config/config.json | jq -r ".colour")

export ENVIRONMENT_SECRETS_PATH=$(pwd)/../secrets/environments/${ENVIRONMENT}/${COLOUR}

eval $(docker-machine env $1)

#$(aws ecr get-login --no-include-email --region eu-west-1)

$2
