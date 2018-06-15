#!/bin/sh

export KAFKA_VERSION=1.1.0
export KAFKA_REVISION=1

docker tag nextbreakpoint/kafka:$KAFKA_VERSION nextbreakpoint/kafka:$KAFKA_VERSION-$KAFKA_REVISION && docker push nextbreakpoint/kafka:$KAFKA_VERSION-$KAFKA_REVISION
