#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/elb && tf_destroy

cd $ROOT/terraform/webserver && tf_destroy &
webserver_pid=$!

cd $ROOT/terraform/pipeline && tf_destroy &
pipeline_pid=$!

cd $ROOT/terraform/ecs && tf_destroy &
ecs_pid=$!

cd $ROOT/terraform/kibana && tf_destroy &
kibana_pid=$!

cd $ROOT/terraform/logstash && tf_destroy &
logstash_pid=$!

cd $ROOT/terraform/elasticsearch && tf_destroy &
elasticsearch_pid=$!

cd $ROOT/terraform/consul && tf_destroy &
consul_pid=$!

wait $webserver_pid
wait $pipeline_pid
wait $ecs_pid
wait $kibana_pid
wait $logstash_pid
wait $elasticsearch_pid
wait $consul_pid

cd $ROOT/terraform/secrets && tf_destroy

cd $ROOT/terraform/dns && tf_destroy
