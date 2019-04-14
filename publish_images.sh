#!/bin/sh

pushd docker/artifactory
sh build.sh
popd

pushd docker/cassandra
sh build.sh
popd

pushd docker/flink
sh build.sh
popd

pushd docker/kafka
sh build.sh
popd

pushd docker/zookeeper
sh build.sh
popd
