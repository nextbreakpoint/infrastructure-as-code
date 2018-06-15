docker run --rm -it \
  --name=kafka \
  --net=kafka \
  -p 9092:9092 \
  -p 9093:9093 \
  -v $(pwd)/secrets:/secrets \
  -e ZK_CONNECT=zookeeper:2181 \
  -e SECURITY_INTER_BROKER_PROTOCOL=SSL \
  -e ADVERTISED_LISTENERS=PLAINTEXT://kafka:9092,SSL://kafka:9093 \
  -e KEYSTORE_LOCATION=/secrets/test-server-keystore.jks \
  -e KEYSTORE_PASSWORD=your_keystore_password \
  -e TRUSTSTORE_LOCATION=/secrets/test-server-truststore.jks \
  -e TRUSTSTORE_PASSWORD=your_truststore_password \
  data-kafka:1.1.0
