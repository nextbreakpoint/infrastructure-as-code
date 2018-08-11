#!/bin/sh

export CASSANDRA_VERSION=3.11

docker build -t nextbreakpoint/cassandra:$CASSANDRA_VERSION --build-arg cassandra_version=$CASSANDRA_VERSION $(pwd)/cassandra
