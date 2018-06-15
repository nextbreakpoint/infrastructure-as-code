#!/bin/sh

docker-machine create -d virtualbox --virtualbox-memory "2048" docker-master
docker-machine create -d virtualbox --virtualbox-memory "4096" docker-worker1
docker-machine create -d virtualbox --virtualbox-memory "4096" docker-worker2
docker-machine create -d virtualbox --virtualbox-memory "4096" docker-worker3
