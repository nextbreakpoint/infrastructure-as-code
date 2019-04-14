#!/bin/sh

exec ./cassandra-initdb.sh &

exec /docker-entrypoint.sh "$@"
