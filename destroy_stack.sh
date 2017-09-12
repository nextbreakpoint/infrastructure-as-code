#!/bin/bash
DIR=$(pwd)
source bash_alias

#cd $DIR/terraform/kafka && tf_destroy -force
#cd $DIR/terraform/cassandra && tf_destroy -force
#cd $DIR/terraform/zookeeper && tf_destroy -force

#cd $DIR/terraform/kibana && tf_destroy -force
#cd $DIR/terraform/logstash && tf_destroy -force
#cd $DIR/terraform/elasticsearch && tf_destroy -force

cd $DIR/terraform/pipeline && tf_destroy -force

#cd $DIR/terraform/consul && tf_destroy -force
