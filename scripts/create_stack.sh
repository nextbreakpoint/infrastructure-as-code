#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/dns && tf_init && tf_plan && tf_apply

cd $ROOT/terraform/secrets && tf_init && tf_plan && tf_apply

cd $ROOT/terraform/consul && tf_init && tf_plan && tf_apply &
consul_pid=$!

cd $ROOT/terraform/elasticsearch && tf_init && tf_plan && tf_apply &
elasticsearch_pid=$!

cd $ROOT/terraform/logstash && tf_init && tf_plan && tf_apply &
logstash_pid=$!

cd $ROOT/terraform/kibana && tf_init && tf_plan && tf_apply &
kibana_pid=$!

cd $ROOT/terraform/ecs && tf_init && tf_plan && tf_apply &
ecs_pid=$!

cd $ROOT/terraform/pipeline && tf_init && tf_plan && tf_apply &
pipeline_pid=$!

cd $ROOT/terraform/webserver && tf_init && tf_plan && tf_apply &
webserver_pid=$!

wait $consul_pid
wait $elasticsearch_pid
wait $logstash_pid
wait $kibana_pid
wait $ecs_pid
wait $pipeline_pid
wait $webserver_pid

cd $ROOT/terraform/elb && tf_init && tf_plan && tf_apply
