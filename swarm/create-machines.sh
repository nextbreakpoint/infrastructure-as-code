#!/bin/sh

docker-machine create -d virtualbox --virtualbox-memory "2048" docker-master
docker-machine create -d virtualbox --virtualbox-memory "3072" docker-worker1
docker-machine create -d virtualbox --virtualbox-memory "3072" docker-worker2
docker-machine create -d virtualbox --virtualbox-memory "3072" docker-worker3

docker-machine ssh docker-master sudo sysctl -w vm.max_map_count=262144
docker-machine ssh docker-worker1 sudo sysctl -w vm.max_map_count=262144
docker-machine ssh docker-worker2 sudo sysctl -w vm.max_map_count=262144
docker-machine ssh docker-worker3 sudo sysctl -w vm.max_map_count=262144

docker-machine ssh docker-master sudo sysctl -w vm.swappiness=1
docker-machine ssh docker-worker1 sudo sysctl -w vm.swappiness=1
docker-machine ssh docker-worker2 sudo sysctl -w vm.swappiness=1
docker-machine ssh docker-worker3 sudo sysctl -w vm.swappiness=1

docker-machine ssh docker-master sudo 'sed -i -e "\$a sysctl -w vm.max_map_count=262144" /var/lib/boot2docker/profile'
docker-machine ssh docker-worker1 sudo 'sed -i -e "\$a sysctl -w vm.max_map_count=262144" /var/lib/boot2docker/profile'
docker-machine ssh docker-worker2 sudo 'sed -i -e "\$a sysctl -w vm.max_map_count=262144" /var/lib/boot2docker/profile'
docker-machine ssh docker-worker3 sudo 'sed -i -e "\$a sysctl -w vm.max_map_count=262144" /var/lib/boot2docker/profile'

docker-machine ssh docker-master sudo 'sed -i -e "\$a sysctl -w vm.swappiness=1" /var/lib/boot2docker/profile'
docker-machine ssh docker-worker1 sudo 'sed -i -e "\$a sysctl -w vm.swappiness=1" /var/lib/boot2docker/profile'
docker-machine ssh docker-worker2 sudo 'sed -i -e "\$a sysctl -w vm.swappiness=1" /var/lib/boot2docker/profile'
docker-machine ssh docker-worker3 sudo 'sed -i -e "\$a sysctl -w vm.swappiness=1" /var/lib/boot2docker/profile'

docker-machine scp daemon.json docker-master:
docker-machine scp daemon.json docker-worker1:
docker-machine scp daemon.json docker-worker2:
docker-machine scp daemon.json docker-worker3:

docker-machine ssh docker-master sudo mv daemon.json /etc/docker
docker-machine ssh docker-worker1 sudo mv daemon.json /etc/docker
docker-machine ssh docker-worker2 sudo mv daemon.json /etc/docker
docker-machine ssh docker-worker3 sudo mv daemon.json /etc/docker

docker-machine ssh docker-master sudo cat /etc/docker/daemon.json
docker-machine ssh docker-worker1 sudo cat /etc/docker/daemon.json
docker-machine ssh docker-worker2 sudo cat /etc/docker/daemon.json
docker-machine ssh docker-worker3 sudo cat /etc/docker/daemon.json

docker-machine ssh docker-master sudo /etc/init.d/docker restart
docker-machine ssh docker-worker1 sudo /etc/init.d/docker restart
docker-machine ssh docker-worker2 sudo /etc/init.d/docker restart
docker-machine ssh docker-worker3 sudo /etc/init.d/docker restart
