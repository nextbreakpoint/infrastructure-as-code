#!/bin/sh

export KAFKA_VERSION=1.1.0

docker build -t nextbreakpoint/kafka:$KAFKA_VERSION --build-arg kafka_version=$KAFKA_VERSION $(pwd)/kafka
