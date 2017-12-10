#!/bin/sh

. $ROOT/bash_aliases

export DIR=$ROOT

cd $DIR/terraform/dns && tf_init && tf_plan && tf_apply

cd $DIR/terraform/secrets && tf_init && tf_plan && tf_apply

cd $DIR/terraform/consul && tf_init && tf_plan && tf_apply &
consul_pid=$!

cd $DIR/terraform/elasticsearch && tf_init && tf_plan && tf_apply &
elasticsearch_pid=$!

cd $DIR/terraform/logstash && tf_init && tf_plan && tf_apply &
logstash_pid=$!

cd $DIR/terraform/kibana && tf_init && tf_plan && tf_apply &
kibana_pid=$!

cd $DIR/terraform/ecs && tf_init && tf_plan && tf_apply &
ecs_pid=$!

cd $DIR/terraform/pipeline && tf_init && tf_plan && tf_apply &
pipeline_pid=$!

cd $DIR/terraform/webserver && tf_init && tf_plan && tf_apply &
webserver_pid=$!

wait $consul_pid
wait $elasticsearch_pid
wait $logstash_pid
wait $kibana_pid
wait $ecs_pid
wait $pipeline_pid
wait $webserver_pid
