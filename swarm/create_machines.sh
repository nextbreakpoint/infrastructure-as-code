#!/bin/sh

docker-machine create -d virtualbox --virtualbox-memory "2048" docker-manager
docker-machine create -d virtualbox --virtualbox-memory "3072" docker-worker1
docker-machine create -d virtualbox --virtualbox-memory "3072" docker-worker2
docker-machine create -d virtualbox --virtualbox-memory "3072" docker-worker3

docker-machine ssh docker-manager sudo sysctl -w vm.max_map_count=1048575
docker-machine ssh docker-worker1 sudo sysctl -w vm.max_map_count=1048575
docker-machine ssh docker-worker2 sudo sysctl -w vm.max_map_count=1048575
docker-machine ssh docker-worker3 sudo sysctl -w vm.max_map_count=1048575

docker-machine ssh docker-manager sudo sysctl -w vm.swappiness=1
docker-machine ssh docker-worker1 sudo sysctl -w vm.swappiness=1
docker-machine ssh docker-worker2 sudo sysctl -w vm.swappiness=1
docker-machine ssh docker-worker3 sudo sysctl -w vm.swappiness=1

docker-machine ssh docker-manager sudo 'sed -i -e "\$a sysctl -w vm.max_map_count=1048575" /var/lib/boot2docker/profile'
docker-machine ssh docker-worker1 sudo 'sed -i -e "\$a sysctl -w vm.max_map_count=1048575" /var/lib/boot2docker/profile'
docker-machine ssh docker-worker2 sudo 'sed -i -e "\$a sysctl -w vm.max_map_count=1048575" /var/lib/boot2docker/profile'
docker-machine ssh docker-worker3 sudo 'sed -i -e "\$a sysctl -w vm.max_map_count=1048575" /var/lib/boot2docker/profile'

docker-machine ssh docker-manager sudo 'sed -i -e "\$a sysctl -w vm.swappiness=1" /var/lib/boot2docker/profile'
docker-machine ssh docker-worker1 sudo 'sed -i -e "\$a sysctl -w vm.swappiness=1" /var/lib/boot2docker/profile'
docker-machine ssh docker-worker2 sudo 'sed -i -e "\$a sysctl -w vm.swappiness=1" /var/lib/boot2docker/profile'
docker-machine ssh docker-worker3 sudo 'sed -i -e "\$a sysctl -w vm.swappiness=1" /var/lib/boot2docker/profile'

docker-machine scp daemon-jsonfile.json docker-manager:
docker-machine scp daemon-jsonfile.json docker-worker1:
docker-machine scp daemon-jsonfile.json docker-worker2:
docker-machine scp daemon-jsonfile.json docker-worker3:

docker-machine ssh docker-manager sudo mv daemon-jsonfile.json /etc/docker
docker-machine ssh docker-worker1 sudo mv daemon-jsonfile.json /etc/docker
docker-machine ssh docker-worker2 sudo mv daemon-jsonfile.json /etc/docker
docker-machine ssh docker-worker3 sudo mv daemon-jsonfile.json /etc/docker

docker-machine ssh docker-manager sudo cat /etc/docker/daemon-jsonfile.json
docker-machine ssh docker-worker1 sudo cat /etc/docker/daemon-jsonfile.json
docker-machine ssh docker-worker2 sudo cat /etc/docker/daemon-jsonfile.json
docker-machine ssh docker-worker3 sudo cat /etc/docker/daemon-jsonfile.json

docker-machine ssh docker-manager sudo /etc/init.d/docker restart
docker-machine ssh docker-worker1 sudo /etc/init.d/docker restart
docker-machine ssh docker-worker2 sudo /etc/init.d/docker restart
docker-machine ssh docker-worker3 sudo /etc/init.d/docker restart
