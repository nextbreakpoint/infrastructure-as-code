#!/bin/bash
DIR=$(pwd)
source bash_alias

cd $DIR/terraform/secrets && tf_init && tf_plan && tf_apply

cd $DIR/terraform/consul && tf_init && tf_plan && tf_apply

cd $DIR/terraform/webserver && tf_init && tf_plan && tf_apply &

cd $DIR/terraform/pipeline && tf_init && tf_plan && tf_apply &

cd $DIR/terraform/elasticsearch && tf_init && tf_plan && tf_apply &

cd $DIR/terraform/logstash && tf_init && tf_plan && tf_apply &

cd $DIR/terraform/kibana && tf_init && tf_plan && tf_apply &

cd $DIR/terraform/ecs && tf_init && tf_plan && tf_apply

cd $DIR/terraform/zookeeper && tf_init && tf_plan && tf_apply

cd $DIR/terraform/kafka && tf_init && tf_plan && tf_apply &

cd $DIR/terraform/cassandra && tf_init && tf_plan && tf_apply &
