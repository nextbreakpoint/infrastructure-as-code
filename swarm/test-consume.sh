#!/bin/sh

docker run --rm -it --net=services \
  -v $(pwd)/../secrets/environments/$ENVIRONMENT/$COLOUR/keystore-server.jks:/secrets/keystore.jks \
  -v $(pwd)/../secrets/environments/$ENVIRONMENT/$COLOUR/truststore-server.jks:/secrets/truststore.jks \
  -v $(pwd)/../secrets/environments/$ENVIRONMENT/$COLOUR/password_keystore.txt:/secrets/password_keystore.txt \
  -v $(pwd)/../secrets/environments/$ENVIRONMENT/$COLOUR/password_truststore.txt:/secrets/password_truststore.txt \
  -v $(pwd)/../secrets/environments/$ENVIRONMENT/$COLOUR/client-ssl.properties:/secrets/client-ssl.properties \
  $KAFKA_IMAGE \
  /opt/kafka_2.11-$KAFKA_VERSION/bin/kafka-console-consumer.sh \
  --bootstrap-server kafka1:9092 \
  --consumer.config /secrets/client-ssl.properties \
  --topic test --from-beginning
