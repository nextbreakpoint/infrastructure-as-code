#!/bin/sh

export HOSTED_ZONE_NAME=$(cat $(pwd)/config/main.json | jq -r ".hosted_zone_name")
export ENVIRONMENT=$(cat $(pwd)/config/main.json | jq -r ".environment")
export COLOUR=$(cat $(pwd)/config/main.json | jq -r ".colour")

export CASSANDRA_USERNAME=$(cat $(pwd)/config/main.json | jq -r ".cassandra_username")
export CASSANDRA_PASSWORD=$(cat $(pwd)/config/main.json | jq -r ".cassandra_password")

export ENVIRONMENT_SECRETS_PATH=$(pwd)/secrets/environments/${ENVIRONMENT}/${COLOUR}

export CASSANDRA_HOST=${ENVIRONMENT}-${COLOUR}-swarm-worker.${HOSTED_ZONE_NAME}

docker run --rm -it -e JVM_OPTS="$JVM_OPTS -Djava.rmi.server.hostname=$CASSANDRA_HOST" cassandra:3.11 nodetool -u $CASSANDRA_USERNAME -pw $CASSANDRA_PASSWORD -h $CASSANDRA_HOST -p 7199 "$@"
