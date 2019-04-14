#!/bin/sh

export SCALA_VERSION=2.11
export KAFKA_VERSION=2.2.0
export IMAGE_REVISION=1

docker build -t nextbreakpoint/kafka:${KAFKA_VERSION}-${IMAGE_REVISION} --build-arg kafka_version=${KAFKA_VERSION} --build-arg scala_version=${SCALA_VERSION} . && docker push nextbreakpoint/kafka:${KAFKA_VERSION}-${IMAGE_REVISION}
