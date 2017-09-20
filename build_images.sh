#!/bin/bash
DIR=$(pwd)
source bash_alias

pushd .
export VPC=$(cd terraform/vpc && terraform output -json network-vpc-id | jq -r '.value')
popd

pushd .
export SUBNET=$(cd terraform/vpc && terraform output -json network-private-subnet-a-id | jq -r '.value')
popd

echo "{\"aws_vpc_id\":\"$VPC\",\"aws_subnet_id\":\"$SUBNET\"}" > network_vars.json

# Create base image
cd $DIR/packer/base && pk_create

# Create images in parallel

cd $DIR/packer/pipeline && pk_create &
pipeline_pid=$!

cd $DIR/packer/puppet && pk_create &
puppet_pid=$!

cd $DIR/packer/nginx && pk_create &
nginx_pid=$!

cd $DIR/packer/elasticsearch && pk_create &
elasticsearch_pid=$!

cd $DIR/packer/logstash && pk_create &
logstash_pid=$!

cd $DIR/packer/kibana && pk_create &
kibana_pid=$!

cd $DIR/packer/zookeeper && pk_create &
zookeeper_pid=$!

cd $DIR/packer/cassandra && pk_create &
cassandra_pid=$!

cd $DIR/packer/kafka && pk_create &
kafka_pid=$!

cd $DIR/packer/kubernetes && pk_create &
kubernetes_pid=$!

# Await termination

wait $pipeline_pid
wait $puppet_pid
wait $nginx_pid
wait $elasticsearch_pid
wait $logstash_pid
wait $kibana_pid
wait $zookeeper_pid
wait $cassandra_pid
wait $kafka_pid
wait $kubernetes_pid
