#!/bin/sh

docker run --rm -it --net=services \
  -v ${ENVIRONMENT_SECRETS_PATH}/keystore-server.jks:/secrets/keystore.jks \
  -v ${ENVIRONMENT_SECRETS_PATH}/truststore-server.jks:/secrets/truststore.jks \
  -v ${ENVIRONMENT_SECRETS_PATH}/password_keystore.txt:/secrets/password_keystore.txt \
  -v ${ENVIRONMENT_SECRETS_PATH}/password_truststore.txt:/secrets/password_truststore.txt \
  -v ${ENVIRONMENT_SECRETS_PATH}/client-ssl.properties:/secrets/client-ssl.properties \
  $KAFKA_IMAGE \
  /opt/kafka_2.11-$KAFKA_VERSION/bin/kafka-console-producer.sh \
  --broker-list kafka1:9092 \
  --producer.config /secrets/client-ssl.properties \
  --topic test --request-timeout-ms 1000
