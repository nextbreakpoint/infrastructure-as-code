#!/bin/sh

export KAFKA_VERSION=1.1.0
export KAFKA_IMAGE=nextbreakpoint/kafka:$KAFKA_VERSION
export DOCKER_MASTER=$(docker-machine ip docker-master)
export DOCKER_HOST_1=$(docker-machine ip docker-worker1)
export DOCKER_HOST_2=$(docker-machine ip docker-worker2)
export DOCKER_HOST_3=$(docker-machine ip docker-worker3)
export SECRETS_PATH=$(pwd)/../secrets/generated
export CONSUL_SECRET=$(cat $(pwd)/../config/consul.tfvars | jq -r ".consul_secret")
export CONSUL_DATACENTER=internal

eval $(docker-machine env $1)

#$(aws ecr get-login --no-include-email --region eu-west-1)

$2
