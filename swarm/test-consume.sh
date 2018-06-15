#!/bin/sh

docker run --rm -it --net=services $KAFKA_IMAGE /opt/kafka_2.11-$KAFKA_VERSION/bin/kafka-console-consumer.sh --bootstrap-server kafka1:9092 --topic test --from-beginning
