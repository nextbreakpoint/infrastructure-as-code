#!/bin/sh

export ENVIRONMENT=$(cat $(pwd)/config/config.json | jq -r ".environment")
export COLOUR=$(cat $(pwd)/config/config.json | jq -r ".colour")

export ENVIRONMENT_SECRETS_PATH=$(pwd)/secrets/environments/${ENVIRONMENT}/${COLOUR}

export SUBNET_A=$(cat $(pwd)/config/network.json | jq -r ".aws_network_private_subnet_cidr_a")
export SUBNET_B=$(cat $(pwd)/config/network.json | jq -r ".aws_network_private_subnet_cidr_b")
export SUBNET_C=$(cat $(pwd)/config/network.json | jq -r ".aws_network_private_subnet_cidr_c")

export MANAGER_A=$(echo ${SUBNET_A} | sed -e "s/\.0\/24/.150/g")
export DOCKER_HOST=tcp://${MANAGER_A}:2376
export DOCKER_TLS=1
export DOCKER_CERT_PATH=${ENVIRONMENT_SECRETS_PATH}/swarm
docker swarm init --advertise-addr ${MANAGER_A}
export MANAGER_TOKEN=$(docker swarm join-token manager | grep "docker swarm join" | awk '{ print $5 }')
export WORKER_TOKEN=$(docker swarm join-token worker | grep "docker swarm join" | awk '{ print $5 }')

export MANAGER_B=$(echo ${SUBNET_B} | sed -e "s/\.0\/24/.150/g")
export DOCKER_HOST=tcp://${MANAGER_B}:2376
docker swarm join --token $MANAGER_TOKEN ${MANAGER_A}:2377

export MANAGER_C=$(echo ${SUBNET_C} | sed -e "s/\.0\/24/.150/g")
export DOCKER_HOST=tcp://${MANAGER_C}:2376
docker swarm join --token $MANAGER_TOKEN ${MANAGER_A}:2377

export WORKER_A=$(echo ${SUBNET_A} | sed -e "s/\.0\/24/.151/g")
export DOCKER_HOST=tcp://${WORKER_A}:2376
docker swarm join --token $WORKER_TOKEN ${MANAGER_A}:2377

export WORKER_B=$(echo ${SUBNET_B} | sed -e "s/\.0\/24/.151/g")
export DOCKER_HOST=tcp://${WORKER_B}:2376
docker swarm join --token $WORKER_TOKEN ${MANAGER_A}:2377

export WORKER_C=$(echo ${SUBNET_C} | sed -e "s/\.0\/24/.151/g")
export DOCKER_HOST=tcp://${WORKER_C}:2376
docker swarm join --token $WORKER_TOKEN ${MANAGER_A}:2377
