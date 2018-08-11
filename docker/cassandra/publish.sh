#!/bin/sh

export CASSANDRA_VERSION=3.11
export CASSANDRA_REVISION=1

docker tag nextbreakpoint/cassandra:$CASSANDRA_VERSION nextbreakpoint/cassandra:$CASSANDRA_VERSION-$CASSANDRA_REVISION && docker push nextbreakpoint/cassandra:$CASSANDRA_VERSION-$CASSANDRA_REVISION
