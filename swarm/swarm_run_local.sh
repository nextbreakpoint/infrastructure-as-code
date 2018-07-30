#!/bin/sh

export KAFKA_VERSION=1.1.0
export KAFKA_REVISION=1
export ZOOKEEPER_VERSION=3.4.12
export ZOOKEEPER_REVISION=1
export ARTIFACTORY_VERSION=5.4.6
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

export ENVIRONMENT=$(cat $(pwd)/../config/main.json | jq -r ".environment")
export COLOUR=$(cat $(pwd)/../config/main.json | jq -r ".colour")

export ENVIRONMENT_SECRETS_PATH=$(pwd)/../secrets/environments/${ENVIRONMENT}/${COLOUR}

export SWARM_RESOURCES_PATH=$(pwd)

export CONSUL_DATACENTER=$(cat $(pwd)/../config/main.json | jq -r ".consul_datacenter")
export CONSUL_SECRET=$(cat $(pwd)/../secrets/consul.json | jq -r ".consul_secret")

export KEYSTORE_PASSWORD=$(cat $(pwd)/../config/main.json | jq -r ".keystore_password")

export ADVERTISE_MANAGER_AGENT_1=$(docker-machine ip docker-master)
export ADVERTISE_MANAGER_AGENT_2=$(docker-machine ip docker-master)
export ADVERTISE_MANAGER_AGENT_3=$(docker-machine ip docker-master)
export ADVERTISE_WORKER_AGENT_1=$(docker-machine ip docker-worker1)
export ADVERTISE_WORKER_AGENT_2=$(docker-machine ip docker-worker2)
export ADVERTISE_WORKER_AGENT_3=$(docker-machine ip docker-worker3)

eval $(docker-machine env $1)

./swarm/$2.sh $3 $4 $5 $6
