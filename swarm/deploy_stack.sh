#!/bin/sh

docker stack deploy -c $SWARM_RESOURCES_PATH/stack-$1.yaml $1 --with-registry-auth
