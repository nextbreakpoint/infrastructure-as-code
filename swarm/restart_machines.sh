#!/bin/sh

docker-machine restart docker-manager
docker-machine restart docker-worker1
docker-machine restart docker-worker2
docker-machine restart docker-worker3
