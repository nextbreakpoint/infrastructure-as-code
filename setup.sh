#!/bin/bash

DIR=$(pwd)
source alias.sh

# Create VPC, Bastion and Network
#cd $DIR/terraform/vpc && tf_init && tf_apply
#cd $DIR/terraform/bastion && tf_init && tf_apply
#cd $DIR/terraform/network && tf_init && tf_apply

# Create AMIs
#cd $DIR/packer && sh build.sh

cd $DIR/terraform/volumes && tf_init && tf_apply

cd $DIR/terraform/consul && tf_init && tf_apply

cd $DIR/terraform/pipeline && tf_init && tf_apply

cd $DIR/terraform/elasticsearch && tf_init && tf_apply
cd $DIR/terraform/logstash && tf_init && tf_apply
cd $DIR/terraform/kibana && tf_init && tf_apply

cd $DIR/terraform/zookeeper && tf_init && tf_apply
cd $DIR/terraform/cassandra && tf_init && tf_apply
cd $DIR/terraform/kafka && tf_init && tf_apply

cd $DIR/terraform/web && tf_init && tf_apply
