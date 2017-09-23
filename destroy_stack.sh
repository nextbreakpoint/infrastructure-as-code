#!/bin/bash
DIR=$(pwd)
source bash_alias

cd $DIR/terraform/ecs && tf_destroy -force

cd $DIR/terraform/kafka && tf_destroy -force &
kafka_pid=$!

cd $DIR/terraform/cassandra && tf_destroy -force &
cassandra_pid=$!

wait $kafka_pid

wait $cassandra_pid

cd $DIR/terraform/zookeeper && tf_destroy -force &
zookeeper_pid=$!

cd $DIR/terraform/kibana && tf_destroy -force &
kibana_pid=$!

cd $DIR/terraform/logstash && tf_destroy -force &
logstash_pid=$!

wait $zookeeper_pid

wait $kibana_pid

wait $logstash_pid

cd $DIR/terraform/elasticsearch && tf_destroy -force &
elasticsearch_pid=$!

cd $DIR/terraform/pipeline && tf_destroy -force &
pipeline_pid=$!

cd $DIR/terraform/webserver && tf_destroy -force &
webserver_pid=$!

wait $elasticsearch_pid

wait $pipeline_pid

wait $webserver_pid

cd $DIR/terraform/consul && tf_destroy -force

cd $DIR/terraform/secrets && tf_destroy -force
