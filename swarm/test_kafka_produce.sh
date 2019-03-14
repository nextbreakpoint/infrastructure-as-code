#!/bin/sh

CONTAINER_ID=$(docker ps --filter name=kafka -q)

docker exec -it $CONTAINER_ID /opt/kafka_2.11-$KAFKA_VERSION/bin/kafka-console-consumer.sh --broker-list kafka1:9092 --producer.config /secrets/client-ssl.properties --topic test --request-timeout-ms 1000
