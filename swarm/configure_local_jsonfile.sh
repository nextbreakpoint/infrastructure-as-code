#!/bin/sh

docker-machine scp daemon-jsonfile.json docker-manager:
docker-machine scp daemon-jsonfile.json docker-worker1:
docker-machine scp daemon-jsonfile.json docker-worker2:
docker-machine scp daemon-jsonfile.json docker-worker3:

docker-machine ssh docker-manager sudo mv daemon-jsonfile.json /etc/docker/daemon.json
docker-machine ssh docker-worker1 sudo mv daemon-jsonfile.json /etc/docker/daemon.json
docker-machine ssh docker-worker2 sudo mv daemon-jsonfile.json /etc/docker/daemon.json
docker-machine ssh docker-worker3 sudo mv daemon-jsonfile.json /etc/docker/daemon.json

docker-machine ssh docker-manager sudo cat /etc/docker/daemon.json
docker-machine ssh docker-worker1 sudo cat /etc/docker/daemon.json
docker-machine ssh docker-worker2 sudo cat /etc/docker/daemon.json
docker-machine ssh docker-worker3 sudo cat /etc/docker/daemon.json

docker-machine ssh docker-manager sudo /etc/init.d/docker restart
docker-machine ssh docker-worker1 sudo /etc/init.d/docker restart
docker-machine ssh docker-worker2 sudo /etc/init.d/docker restart
docker-machine ssh docker-worker3 sudo /etc/init.d/docker restart
