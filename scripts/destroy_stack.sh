#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/webserver && tf_destroy

cd $ROOT/terraform/pipeline && tf_destroy

cd $ROOT/terraform/ecs && tf_destroy

cd $ROOT/terraform/kibana && tf_destroy

cd $ROOT/terraform/logstash && tf_destroy

cd $ROOT/terraform/elasticsearch && tf_destroy

cd $ROOT/terraform/consul && tf_destroy

cd $ROOT/terraform/secrets && tf_destroy
