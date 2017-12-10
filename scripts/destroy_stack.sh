#!/bin/sh

. $ROOT/bash_aliases

export DIR=$ROOT

cd $DIR/terraform/webserver && tf_destroy &
webserver_pid=$!

cd $DIR/terraform/pipeline && tf_destroy &
pipeline_pid=$!

cd $DIR/terraform/ecs && tf_destroy &
ecs_pid=$!

cd $DIR/terraform/kibana && tf_destroy &
kibana_pid=$!

cd $DIR/terraform/logstash && tf_destroy &
logstash_pid=$!

cd $DIR/terraform/elasticsearch && tf_destroy &
elasticsearch_pid=$!

cd $DIR/terraform/consul && tf_destroy &
consul_pid=$!

wait $webserver_pid
wait $pipeline_pid
wait $ecs_pid
wait $kibana_pid
wait $logstash_pid
wait $elasticsearch_pid
wait $consul_pid

cd $DIR/terraform/secrets && tf_destroy

cd $DIR/terraform/dns && tf_destroy
