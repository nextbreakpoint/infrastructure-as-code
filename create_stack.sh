#!/bin/bash
DIR=$(pwd)
source bash_alias

cd $DIR/terraform/secrets && tf_init && tf_plan && tf_apply

cd $DIR/terraform/consul && tf_init && tf_plan && tf_apply

cd $DIR/terraform/webserver && tf_init && tf_plan && tf_apply &
webserver_pid=$!

cd $DIR/terraform/pipeline && tf_init && tf_plan && tf_apply &
pipeline_pid=$!

cd $DIR/terraform/elasticsearch && tf_init && tf_plan && tf_apply &
elasticsearch_pid=$!

wait $webserver_pid

wait $pipeline_pid

wait $elasticsearch_pid

cd $DIR/terraform/logstash && tf_init && tf_plan && tf_apply &
logstash_pid=$!

cd $DIR/terraform/kibana && tf_init && tf_plan && tf_apply &
kibana_pid=$!

cd $DIR/terraform/zookeeper && tf_init && tf_plan && tf_apply &
zookeeper_pid=$!

wait $logstash_pid

wait $kibana_pid

wait $zookeeper_pid

cd $DIR/terraform/cassandra && tf_init && tf_plan && tf_apply &
cassandra_pid=$!

cd $DIR/terraform/kafka && tf_init && tf_plan && tf_apply &
kafka_pid=$!

wait $cassandra_pid

wait $kafka_pid

cd $DIR/terraform/ecs && tf_init && tf_plan && tf_apply
