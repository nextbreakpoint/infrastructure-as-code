#!/bin/sh

export HOSTED_ZONE_NAME=$(cat $(pwd)/config/main.json | jq -r ".hosted_zone_name")
export ENVIRONMENT=$(cat $(pwd)/config/main.json | jq -r ".environment")
export COLOUR=$(cat $(pwd)/config/main.json | jq -r ".colour")

export ENVIRONMENT_SECRETS_PATH=$(pwd)/secrets/environments/${ENVIRONMENT}/${COLOUR}

export MANAGER_A=${ENVIRONMENT}-${COLOUR}-swarm-manager-a.${HOSTED_ZONE_NAME}
export DOCKER_HOST=tcp://${MANAGER_A}:2376
export DOCKER_TLS=1
export DOCKER_CERT_PATH=${ENVIRONMENT_SECRETS_PATH}/swarm
docker swarm init --advertise-addr $(host ${ENVIRONMENT}-${COLOUR}-swarm-manager-a.${HOSTED_ZONE_NAME} | grep -m1 " has address " | awk '{ print $4 }')
export MANAGER_TOKEN=$(docker swarm join-token manager | grep "docker swarm join" | awk '{ print $5 }')
export WORKER_TOKEN=$(docker swarm join-token worker | grep "docker swarm join" | awk '{ print $5 }')

export MANAGER_B=${ENVIRONMENT}-${COLOUR}-swarm-manager-b.${HOSTED_ZONE_NAME}
export DOCKER_HOST=tcp://${MANAGER_B}:2376
docker swarm join --token $MANAGER_TOKEN ${MANAGER_A}:2377

export MANAGER_C=${ENVIRONMENT}-${COLOUR}-swarm-manager-c.${HOSTED_ZONE_NAME}
export DOCKER_HOST=tcp://${MANAGER_C}:2376
docker swarm join --token $MANAGER_TOKEN ${MANAGER_A}:2377

export WORKER_A=${ENVIRONMENT}-${COLOUR}-swarm-worker-int-a.${HOSTED_ZONE_NAME}
export DOCKER_HOST=tcp://${WORKER_A}:2376
docker swarm join --token $WORKER_TOKEN ${MANAGER_A}:2377

export WORKER_B=${ENVIRONMENT}-${COLOUR}-swarm-worker-int-b.${HOSTED_ZONE_NAME}
export DOCKER_HOST=tcp://${WORKER_B}:2376
docker swarm join --token $WORKER_TOKEN ${MANAGER_A}:2377

export WORKER_C=${ENVIRONMENT}-${COLOUR}-swarm-worker-int-c.${HOSTED_ZONE_NAME}
export DOCKER_HOST=tcp://${WORKER_C}:2376
docker swarm join --token $WORKER_TOKEN ${MANAGER_A}:2377

export WORKER_A=${ENVIRONMENT}-${COLOUR}-swarm-worker-ext-a.${HOSTED_ZONE_NAME}
export DOCKER_HOST=tcp://${WORKER_A}:2376
docker swarm join --token $WORKER_TOKEN ${MANAGER_A}:2377

export WORKER_B=${ENVIRONMENT}-${COLOUR}-swarm-worker-ext-b.${HOSTED_ZONE_NAME}
export DOCKER_HOST=tcp://${WORKER_B}:2376
docker swarm join --token $WORKER_TOKEN ${MANAGER_A}:2377

export WORKER_C=${ENVIRONMENT}-${COLOUR}-swarm-worker-ext-c.${HOSTED_ZONE_NAME}
export DOCKER_HOST=tcp://${WORKER_C}:2376
docker swarm join --token $WORKER_TOKEN ${MANAGER_A}:2377
