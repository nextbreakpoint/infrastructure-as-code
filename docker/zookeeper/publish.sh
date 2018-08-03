#!/bin/sh

export ZOOKEEPER_VERSION=3.4.12
export ZOOKEEPER_REVISION=1

docker tag nextbreakpoint/zookeeper:$ZOOKEEPER_VERSION nextbreakpoint/zookeeper:$ZOOKEEPER_VERSION-$ZOOKEEPER_REVISION && docker push nextbreakpoint/zookeeper:$ZOOKEEPER_VERSION-$ZOOKEEPER_REVISION
