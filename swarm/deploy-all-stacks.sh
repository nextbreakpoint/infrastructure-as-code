#!/bin/sh

eval $(docker-machine env docker-master)

./deploy-stack.sh logstash
./deploy-stack.sh elasticsearch
./deploy-stack.sh kibana
./deploy-stack.sh zookeeper
./deploy-stack.sh kafka
./deploy-stack.sh cassandra
./deploy-stack.sh graphite
./deploy-stack.sh grafana
./deploy-stack.sh consul
./deploy-stack.sh nginx
