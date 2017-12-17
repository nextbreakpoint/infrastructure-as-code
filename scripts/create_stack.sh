#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/secrets && tf_init
cd $ROOT/terraform/consul && tf_init
cd $ROOT/terraform/elasticsearch && tf_init
cd $ROOT/terraform/logstash && tf_init
cd $ROOT/terraform/kibana && tf_init
cd $ROOT/terraform/ecs && tf_init
cd $ROOT/terraform/pipeline && tf_init
cd $ROOT/terraform/webserver && tf_init

cd $ROOT/terraform/secrets && tf_plan
cd $ROOT/terraform/consul && tf_plan
cd $ROOT/terraform/elasticsearch && tf_plan
cd $ROOT/terraform/logstash && tf_plan
cd $ROOT/terraform/kibana && tf_plan
cd $ROOT/terraform/ecs && tf_plan
cd $ROOT/terraform/pipeline && tf_plan
cd $ROOT/terraform/webserver && tf_plan

cd $ROOT/terraform/secrets && tf_apply
cd $ROOT/terraform/consul && tf_apply
cd $ROOT/terraform/elasticsearch && tf_apply
cd $ROOT/terraform/logstash && tf_apply
cd $ROOT/terraform/kibana && tf_apply
cd $ROOT/terraform/ecs && tf_apply
cd $ROOT/terraform/pipeline && tf_apply
cd $ROOT/terraform/webserver && tf_apply
