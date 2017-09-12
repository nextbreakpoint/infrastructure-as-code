#!/bin/bash
DIR=$(pwd)
source ../alias.sh

# Create base image

cd $DIR/base && pk_create

# Create other images in parallel

cd $DIR/pipeline && pk_create &
pipeline_pid=$!

cd $DIR/puppet && pk_create &
puppet_pid=$!

cd $DIR/elasticsearch && pk_create &
elasticsearch_pid=$!

cd $DIR/logstash && pk_create &
logstash_pid=$!

cd $DIR/kibana && pk_create &
kibana_pid=$!

cd $DIR/zookeeper && pk_create &
zookeeper_pid=$!

cd $DIR/cassandra && pk_create &
cassandra_pid=$!

cd $DIR/kafka && pk_create &
kafka_pid=$!

cd $DIR/kubernetes && pk_create &
kubernetes_pid=$!

# Await termination
wait $pipeline_pid
wait $puppet_pid
wait $elasticsearch_pid
wait $logstash_pid
wait $kibana_pid
wait $zookeeper_pid
wait $cassandra_pid
wait $kafka_pid
wait $kubernetes_pid
