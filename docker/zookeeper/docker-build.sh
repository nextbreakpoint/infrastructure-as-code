#!/bin/sh

export ZOOKEEPER_VERSION=3.4.12

docker build -t nextbreakpoint/zookeeper:$ZOOKEEPER_VERSION --build-arg zookeeper_version=$ZOOKEEPER_VERSION $(pwd)/zookeeper
