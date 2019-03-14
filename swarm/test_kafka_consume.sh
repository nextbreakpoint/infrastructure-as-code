#!/bin/sh

CONTAINER_ID=$(docker ps --filter name=kafka -q)

docker exec -it $CONTAINER_ID /opt/kafka_2.11-$KAFKA_VERSION/bin/kafka-console-consumer.sh --bootstrap-server kafka1:9092 --consumer.config /secrets/client-ssl.properties --topic test --from-beginning
