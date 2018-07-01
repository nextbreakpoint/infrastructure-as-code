#!/bin/sh

eval $(docker-machine env docker-master)

export NODE=$(docker node ls -q --filter "name=docker-master")

docker node update --label-add postgres=true $NODE
docker node update --label-add jenkins=true $NODE
docker node update --label-add sonarqube=true $NODE
docker node update --label-add artifactory=true $NODE
docker node update --label-add elasticsearch=true $NODE
docker node update --label-add logstash=true $NODE
docker node update --label-add graphite=true $NODE
docker node update --label-add grafana=true $NODE
docker node update --label-add kibana=true $NODE
docker node update --label-add consul=true $NODE
docker node update --label-add agent=true $NODE
docker node update --label-add zone=a $NODE

export NODE=$(docker node ls -q --filter "name=docker-worker1")

docker node update --label-add zone=a $NODE
docker node update --label-add consul=true $NODE
docker node update --label-add kafka=true $NODE
docker node update --label-add zookeeper=true $NODE
docker node update --label-add elasticsearch=true $NODE
docker node update --label-add logstash=true $NODE
docker node update --label-add cassandra=true $NODE
docker node update --label-add nginx=true $NODE
docker node update --label-add agent=true $NODE
docker node update --role worker $NODE

export NODE=$(docker node ls -q --filter "name=docker-worker2")

docker node update --label-add zone=b $NODE
docker node update --label-add consul=true $NODE
docker node update --label-add kafka=true $NODE
docker node update --label-add zookeeper=true $NODE
docker node update --label-add elasticsearch=true $NODE
docker node update --label-add logstash=true $NODE
docker node update --label-add cassandra=true $NODE
docker node update --label-add nginx=true $NODE
docker node update --label-add agent=true $NODE
docker node update --role worker $NODE

export NODE=$(docker node ls -q --filter "name=docker-worker3")

docker node update --label-add zone=c $NODE
docker node update --label-add consul=true $NODE
docker node update --label-add kafka=true $NODE
docker node update --label-add zookeeper=true $NODE
docker node update --label-add elasticsearch=true $NODE
docker node update --label-add logstash=true $NODE
docker node update --label-add cassandra=true $NODE
docker node update --label-add nginx=true $NODE
docker node update --label-add agent=true $NODE
docker node update --role worker $NODE
