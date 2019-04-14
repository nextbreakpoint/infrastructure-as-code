#!/bin/sh

export ZOOKEEPER_VERSION=3.4.12
export IMAGE_VERSION=1

docker build -t nextbreakpoint/zookeeper:${ZOOKEEPER_VERSION}-${IMAGE_VERSION} --build-arg zookeeper_version=${ZOOKEEPER_VERSION} . && docker push nextbreakpoint/zookeeper:${ZOOKEEPER_VERSION}-${IMAGE_VERSION}
