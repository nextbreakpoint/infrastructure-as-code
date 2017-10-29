#!/bin/bash
DIR=$(pwd)
source bash_alias

cd $DIR/terraform/ecs && tf_destroy

cd $DIR/terraform/kafka && tf_destroy &
kafka_pid=$!

cd $DIR/terraform/cassandra && tf_destroy &
cassandra_pid=$!

wait $kafka_pid

wait $cassandra_pid

cd $DIR/terraform/zookeeper && tf_destroy &
zookeeper_pid=$!

cd $DIR/terraform/kibana && tf_destroy &
kibana_pid=$!

cd $DIR/terraform/logstash && tf_destroy &
logstash_pid=$!

wait $zookeeper_pid

wait $kibana_pid

wait $logstash_pid

cd $DIR/terraform/elasticsearch && tf_destroy &
elasticsearch_pid=$!

cd $DIR/terraform/pipeline && tf_destroy &
pipeline_pid=$!

cd $DIR/terraform/webserver && tf_destroy &
webserver_pid=$!

wait $elasticsearch_pid

wait $pipeline_pid

wait $webserver_pid

cd $DIR/terraform/consul && tf_destroy

cd $DIR/terraform/secrets && tf_destroy
