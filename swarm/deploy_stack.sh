#!/bin/sh

docker stack deploy -c stack-$1.yaml $1 --with-registry-auth
