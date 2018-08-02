#!/bin/sh

export HOSTED_ZONE_NAME=$(cat $(pwd)/config/main.json | jq -r ".hosted_zone_name")
export ENVIRONMENT=$(cat $(pwd)/config/main.json | jq -r ".environment")
export COLOUR=$(cat $(pwd)/config/main.json | jq -r ".colour")

export SUBNET_A=$(cat $(pwd)/config/network.json | jq -r ".aws_network_private_subnet_cidr_a")
export SUBNET_B=$(cat $(pwd)/config/network.json | jq -r ".aws_network_private_subnet_cidr_b")
export SUBNET_C=$(cat $(pwd)/config/network.json | jq -r ".aws_network_private_subnet_cidr_c")

export ENVIRONMENT_SECRETS_PATH=$(pwd)/secrets/environments/${ENVIRONMENT}/${COLOUR}

export DOCKER_HOST=tcp://${ENVIRONMENT}-${COLOUR}-swarm-manager.${HOSTED_ZONE_NAME}:2376
export DOCKER_TLS=1
export DOCKER_CERT_PATH=${ENVIRONMENT_SECRETS_PATH}/swarm

export MANAGER_A=$(echo ${SUBNET_A} | sed -e "s/\.0\/24/.150/g")
export NODE=$(docker node ls -q --filter "name=$(echo ${MANAGER_A} | sed -E "s/([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)/ip-\1-\2-\3-\4/g")")

docker node update --label-add zone=a $NODE
docker node update --label-add elasticsearch=true $NODE
docker node update --label-add logstash=true $NODE
docker node update --label-add consul=true $NODE
docker node update --label-add agent=true $NODE
docker node update --label-add postgres=true $NODE
docker node update --label-add mysql=true $NODE
docker node update --label-add jenkins=true $NODE
docker node update --label-add sonarqube=true $NODE
docker node update --label-add artifactory=true $NODE

export MANAGER_B=$(echo ${SUBNET_B} | sed -e "s/\.0\/24/.150/g")
export NODE=$(docker node ls -q --filter "name=$(echo ${MANAGER_B} | sed -E "s/([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)/ip-\1-\2-\3-\4/g")")

docker node update --label-add zone=b $NODE
docker node update --label-add elasticsearch=true $NODE
docker node update --label-add logstash=true $NODE
docker node update --label-add consul=true $NODE
docker node update --label-add agent=true $NODE
docker node update --label-add graphite=true $NODE
docker node update --label-add grafana=true $NODE

export MANAGER_C=$(echo ${SUBNET_C} | sed -e "s/\.0\/24/.150/g")
export NODE=$(docker node ls -q --filter "name=$(echo ${MANAGER_C} | sed -E "s/([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)/ip-\1-\2-\3-\4/g")")

docker node update --label-add zone=c $NODE
docker node update --label-add elasticsearch=true $NODE
docker node update --label-add logstash=true $NODE
docker node update --label-add consul=true $NODE
docker node update --label-add agent=true $NODE
docker node update --label-add kibana=true $NODE

export WORKER_A=$(echo ${SUBNET_A} | sed -e "s/\.0\/24/.151/g")
export NODE=$(docker node ls -q --filter "name=$(echo ${WORKER_A} | sed -E "s/([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)/ip-\1-\2-\3-\4/g")")

docker node update --label-add zone=a $NODE
docker node update --label-add consul=true $NODE
docker node update --label-add kafka=true $NODE
docker node update --label-add zookeeper=true $NODE
docker node update --label-add elasticsearch=true $NODE
docker node update --label-add logstash=true $NODE
docker node update --label-add cassandra=true $NODE
docker node update --label-add nginx=true $NODE
docker node update --label-add agent=true $NODE

export WORKER_B=$(echo ${SUBNET_B} | sed -e "s/\.0\/24/.151/g")
export NODE=$(docker node ls -q --filter "name=$(echo ${WORKER_B} | sed -E "s/([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)/ip-\1-\2-\3-\4/g")")

docker node update --label-add zone=b $NODE
docker node update --label-add consul=true $NODE
docker node update --label-add kafka=true $NODE
docker node update --label-add zookeeper=true $NODE
docker node update --label-add elasticsearch=true $NODE
docker node update --label-add logstash=true $NODE
docker node update --label-add cassandra=true $NODE
docker node update --label-add nginx=true $NODE
docker node update --label-add agent=true $NODE

export WORKER_C=$(echo ${SUBNET_C} | sed -e "s/\.0\/24/.151/g")
export NODE=$(docker node ls -q --filter "name=$(echo ${WORKER_C} | sed -E "s/([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)/ip-\1-\2-\3-\4/g")")

docker node update --label-add zone=c $NODE
docker node update --label-add consul=true $NODE
docker node update --label-add kafka=true $NODE
docker node update --label-add zookeeper=true $NODE
docker node update --label-add elasticsearch=true $NODE
docker node update --label-add logstash=true $NODE
docker node update --label-add cassandra=true $NODE
docker node update --label-add nginx=true $NODE
docker node update --label-add agent=true $NODE
