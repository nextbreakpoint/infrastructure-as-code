#!/bin/sh

eval $(docker-machine env docker-master)

./remove-stack.sh consul
./remove-stack.sh grafana
./remove-stack.sh graphite
./remove-stack.sh cassandra
./remove-stack.sh kafka
./remove-stack.sh zookeeper
./remove-stack.sh kibana
./remove-stack.sh elasticsearch
./remove-stack.sh logstash
