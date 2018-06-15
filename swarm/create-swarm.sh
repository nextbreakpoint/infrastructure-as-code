#!/bin/sh

eval $(docker-machine env docker-master)

docker swarm init --advertise-addr $(docker-machine ip docker-master)

export NODE=$(docker node ls -q --filter "name=docker-master")

docker node update --label-add postgres=true $NODE

export TOKEN=$(docker swarm join-token manager | grep "docker swarm join" | awk '{ print $5 }')

eval $(docker-machine env docker-worker1)

docker swarm join --token $TOKEN $(docker-machine ip docker-master):2377

export NODE=$(docker node ls -q --filter "name=docker-worker1")

docker node update --label-add zone=a $NODE
docker node update --label-add kafka=true $NODE
docker node update --label-add zookeeper=true $NODE
docker node update --role worker $NODE

eval $(docker-machine env docker-worker2)

docker swarm join --token $TOKEN $(docker-machine ip docker-master):2377

export NODE=$(docker node ls -q --filter "name=docker-worker2")

docker node update --label-add zone=b $NODE
docker node update --label-add kafka=true $NODE
docker node update --label-add zookeeper=true $NODE
docker node update --role worker $NODE

eval $(docker-machine env docker-worker3)

docker swarm join --token $TOKEN $(docker-machine ip docker-master):2377

export NODE=$(docker node ls -q --filter "name=docker-worker3")

docker node update --label-add zone=c $NODE
docker node update --label-add kafka=true $NODE
docker node update --label-add zookeeper=true $NODE
docker node update --role worker $NODE
