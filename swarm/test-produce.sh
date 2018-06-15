#!/bin/sh

docker run --rm -it --net=services $KAFKA_IMAGE /opt/kafka_2.11-$KAFKA_VERSION/bin/kafka-console-producer.sh --broker-list kafka1:9092 --topic test --request-timeout-ms 1000
