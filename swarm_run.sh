#!/bin/sh

export KAFKA_VERSION=1.1.0
export KAFKA_REVISION=1
export ZOOKEEPER_VERSION=3.4.12
export ZOOKEEPER_REVISION=1
export ARTIFACTORY_VERSION=6.1.0
export ARTIFACTORY_REVISION=1
export ELASTICSTACK_VERSION=5.6.10
export CASSANDRA_VERSION=3.11
export CONSUL_VERSION=latest
export GRAPHITE_VERSION=latest
export GRAFANA_VERSION=5.2.0
export NGINX_VERSION=latest
export SONARQUBE_VERSION=6.5

export KAFKA_IMAGE=nextbreakpoint/kafka:$KAFKA_VERSION-$KAFKA_REVISION
export ZOOKEEPER_IMAGE=nextbreakpoint/zookeeper:$ZOOKEEPER_VERSION-$ZOOKEEPER_REVISION
export ARTIFACTORY_IMAGE=nextbreakpoint/artifactory:$ARTIFACTORY_VERSION-$ARTIFACTORY_REVISION
export ELASTICSEARCH_IMAGE=docker.elastic.co/elasticsearch/elasticsearch:${ELASTICSTACK_VERSION}
export LOGSTASH_IMAGE=docker.elastic.co/logstash/logstash:${ELASTICSTACK_VERSION}
export KIBANA_IMAGE=docker.elastic.co/kibana/kibana:${ELASTICSTACK_VERSION}
export CASSANDRA_IMAGE=cassandra:${CASSANDRA_VERSION}
export CONSUL_IMAGE=consul:${CONSUL_VERSION}
export GRAPHITE_IMAGE=graphiteapp/graphite-statsd:${GRAPHITE_VERSION}
export GRAFANA_IMAGE=grafana/grafana:${GRAFANA_VERSION}
export NGINX_IMAGE=nginx:${NGINX_VERSION}
export SONARQUBE_IMAGE=sonarqube:${SONARQUBE_VERSION}

export HOSTED_ZONE_NAME=$(cat $(pwd)/config/main.json | jq -r ".hosted_zone_name")
export ENVIRONMENT=$(cat $(pwd)/config/main.json | jq -r ".environment")
export COLOUR=$(cat $(pwd)/config/main.json | jq -r ".colour")

export ENVIRONMENT_SECRETS_PATH=$(pwd)/secrets/environments/${ENVIRONMENT}/${COLOUR}

export SWARM_RESOURCES_PATH=$(pwd)/swarm

export CONSUL_DATACENTER=$(cat $(pwd)/config/main.json | jq -r ".consul_datacenter")
export CONSUL_SECRET=$(cat $(pwd)/secrets/consul.json | jq -r ".consul_secret")

export HOSTED_ZONE_NAME=$(cat $(pwd)/config/main.json | jq -r ".hosted_zone_name")

export KEYSTORE_PASSWORD=$(cat $(pwd)/config/main.json | jq -r ".keystore_password")

export SUBNET_A=$(cat $(pwd)/config/network.json | jq -r ".aws_network_private_subnet_cidr_a")
export SUBNET_B=$(cat $(pwd)/config/network.json | jq -r ".aws_network_private_subnet_cidr_b")
export SUBNET_C=$(cat $(pwd)/config/network.json | jq -r ".aws_network_private_subnet_cidr_c")

export MANAGER_A=$(echo ${SUBNET_A} | sed -e "s/\.0\/24/.150/g")
export MANAGER_B=$(echo ${SUBNET_B} | sed -e "s/\.0\/24/.150/g")
export MANAGER_C=$(echo ${SUBNET_C} | sed -e "s/\.0\/24/.150/g")
export WORKER_A=$(echo ${SUBNET_A} | sed -e "s/\.0\/24/.151/g")
export WORKER_B=$(echo ${SUBNET_B} | sed -e "s/\.0\/24/.151/g")
export WORKER_C=$(echo ${SUBNET_C} | sed -e "s/\.0\/24/.151/g")

export ADVERTISE_MANAGER_AGENT_1=$MANAGER_A
export ADVERTISE_MANAGER_AGENT_2=$MANAGER_B
export ADVERTISE_MANAGER_AGENT_3=$MANAGER_C
export ADVERTISE_WORKER_AGENT_1=$WORKER_A
export ADVERTISE_WORKER_AGENT_2=$WORKER_B
export ADVERTISE_WORKER_AGENT_3=$WORKER_C

export DOCKER_HOST=tcp://${ENVIRONMENT}-${COLOUR}-swarm-manager.${HOSTED_ZONE_NAME}:2376
export DOCKER_TLS=1
export DOCKER_CERT_PATH=${ENVIRONMENT_SECRETS_PATH}/swarm

./swarm/$1.sh $2 $3 $4 $5
