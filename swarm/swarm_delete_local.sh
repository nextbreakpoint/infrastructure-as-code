#!/bin/sh

eval $(docker-machine env docker-master)
docker swarm leave -f

eval $(docker-machine env docker-worker1)
docker swarm leave -f

eval $(docker-machine env docker-worker2)
docker swarm leave -f

eval $(docker-machine env docker-worker3)
docker swarm leave -f
