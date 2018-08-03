#!/bin/sh

eval $(docker-machine env docker-master)

docker swarm init --advertise-addr $(docker-machine ip docker-master)

export TOKEN=$(docker swarm join-token manager | grep "docker swarm join" | awk '{ print $5 }')

eval $(docker-machine env docker-worker1)

docker swarm join --token $TOKEN $(docker-machine ip docker-master):2377

eval $(docker-machine env docker-worker2)

docker swarm join --token $TOKEN $(docker-machine ip docker-master):2377

eval $(docker-machine env docker-worker3)

docker swarm join --token $TOKEN $(docker-machine ip docker-master):2377
