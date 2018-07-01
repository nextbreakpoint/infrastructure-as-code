#!/bin/sh

export KAFKA_VERSION=1.1.0
export KAFKA_REVISION=1
export ZOOKEEPER_VERSION=3.4.12
export ZOOKEEPER_REVISION=1
export ELASTICSTACK_VERSION=5.6.10
export KAFKA_IMAGE=nextbreakpoint/kafka:$KAFKA_VERSION-$KAFKA_REVISION
export ZOOKEEPER_IMAGE=nextbreakpoint/zookeeper:$ZOOKEEPER_VERSION-$ZOOKEEPER_REVISION
export ELASTICSEARCH_IMAGE=docker.elastic.co/elasticsearch/elasticsearch:${ELASTICSTACK_VERSION}
export LOGSTASH_IMAGE=docker.elastic.co/logstash/logstash:${ELASTICSTACK_VERSION}
export KIBANA_IMAGE=docker.elastic.co/kibana/kibana:${ELASTICSTACK_VERSION}
export CASSANDRA_IMAGE=cassandra:3.11
export CONSUL_IMAGE=consul:latest
export GRAPHITE_IMAGE=graphiteapp/graphite-statsd:latest
export GRAFANA_IMAGE=grafana/grafana:5.2.0
export SECRETS_PATH=$(pwd)/../secrets/generated
export CONSUL_SECRET=$(cat $(pwd)/../config/consul.tfvars | jq -r ".consul_secret")
export CONSUL_DATACENTER=internal

eval $(docker-machine env $1)

#$(aws ecr get-login --no-include-email --region eu-west-1)

$2
