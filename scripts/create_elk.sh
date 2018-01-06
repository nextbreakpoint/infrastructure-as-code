#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/elasticsearch && tf_init
cd $ROOT/terraform/logstash && tf_init
cd $ROOT/terraform/kibana && tf_init

cd $ROOT/terraform/elasticsearch && tf_plan
cd $ROOT/terraform/logstash && tf_plan
cd $ROOT/terraform/kibana && tf_plan

cd $ROOT/terraform/elasticsearch && tf_apply
cd $ROOT/terraform/logstash && tf_apply
cd $ROOT/terraform/kibana && tf_apply
