#!/bin/sh

docker run --rm -it --net=services \
  -v $SECRETS_PATH/kafka1-server-keystore.jks:/secrets/keystore.jks \
  -v $SECRETS_PATH/kafka1-server-truststore.jks:/secrets/truststore.jks \
  -v $(pwd)/password_keystore.txt:/secrets/password_keystore.txt \
  -v $(pwd)/password_truststore.txt:/secrets/password_truststore.txt \
  -v $(pwd)/client-ssl.properties:/secrets/client-ssl.properties \
  $KAFKA_IMAGE \
  /opt/kafka_2.11-$KAFKA_VERSION/bin/kafka-console-producer.sh \
  --broker-list kafka1:9092 \
  --producer.config /secrets/client-ssl.properties \
  --topic test --request-timeout-ms 1000
