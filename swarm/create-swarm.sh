#!/bin/sh

eval $(docker-machine env docker-master)

docker swarm init --advertise-addr $(docker-machine ip docker-master)

export NODE=$(docker node ls -q --filter "name=docker-master")

docker node update --label-add postgres=true $NODE
docker node update --label-add jenkins=true $NODE
docker node update --label-add sonarqube=true $NODE
docker node update --label-add artifactory=true $NODE
docker node update --label-add openvpn=true $NODE
docker node update --label-add elasticsearch=true $NODE
docker node update --label-add logstash=true $NODE
docker node update --label-add graphite=true $NODE
docker node update --label-add grafana=true $NODE
docker node update --label-add kibana=true $NODE
docker node update --label-add consul=true $NODE
docker node update --label-add zone=a $NODE

export TOKEN=$(docker swarm join-token manager | grep "docker swarm join" | awk '{ print $5 }')

eval $(docker-machine env docker-worker1)

docker swarm join --token $TOKEN $(docker-machine ip docker-master):2377

export NODE=$(docker node ls -q --filter "name=docker-worker1")

docker node update --label-add zone=a $NODE
docker node update --label-add consul=true $NODE
docker node update --label-add kafka=true $NODE
docker node update --label-add zookeeper=true $NODE
docker node update --label-add elasticsearch=true $NODE
docker node update --label-add logstash=true $NODE
docker node update --label-add cassandra=true $NODE
docker node update --label-add nginx=true $NODE
docker node update --role worker $NODE

eval $(docker-machine env docker-worker2)

docker swarm join --token $TOKEN $(docker-machine ip docker-master):2377

export NODE=$(docker node ls -q --filter "name=docker-worker2")

docker node update --label-add zone=b $NODE
docker node update --label-add consul=true $NODE
docker node update --label-add kafka=true $NODE
docker node update --label-add zookeeper=true $NODE
docker node update --label-add elasticsearch=true $NODE
docker node update --label-add logstash=true $NODE
docker node update --label-add cassandra=true $NODE
docker node update --label-add nginx=true $NODE
docker node update --role worker $NODE

eval $(docker-machine env docker-worker3)

docker swarm join --token $TOKEN $(docker-machine ip docker-master):2377

export NODE=$(docker node ls -q --filter "name=docker-worker3")

docker node update --label-add zone=c $NODE
docker node update --label-add consul=true $NODE
docker node update --label-add kafka=true $NODE
docker node update --label-add zookeeper=true $NODE
docker node update --label-add elasticsearch=true $NODE
docker node update --label-add logstash=true $NODE
docker node update --label-add cassandra=true $NODE
docker node update --label-add nginx=true $NODE
docker node update --role worker $NODE

eval $(docker-machine env docker-master)

docker network create -d overlay --attachable services
