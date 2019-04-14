#!/bin/sh

export CASSANDRA_VERSION=3.11
export IMAGE_REVISION=1

docker build -t nextbreakpoint/cassandra:${CASSANDRA_VERSION}-${IMAGE_REVISION} --build-arg cassandra_version=${CASSANDRA_VERSION} . && docker push nextbreakpoint/cassandra:${CASSANDRA_VERSION}-${IMAGE_REVISION}
