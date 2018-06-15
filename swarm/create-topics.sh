#!/bin/sh

docker run --rm -it --net=services $KAFKA_IMAGE /opt/kafka_2.11-$KAFKA_VERSION/bin/kafka-topics.sh --create --zookeeper zookeeper1:2181 --replication-factor 1 --partitions 10 --topic test
