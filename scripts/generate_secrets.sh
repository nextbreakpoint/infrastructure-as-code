#!/bin/sh

ENVIRONMENT=$(cat $ROOT/config/config.json | jq -r ".environment")
COLOUR=$(cat $ROOT/config/config.json | jq -r ".colour")

CONSUL_DATACENTER=$(cat $ROOT/config/config.json | jq -r ".consul_datacenter")

KAFKA_PASSWORD=$(cat $ROOT/config/config.json | jq -r ".kafka_password")
ZOO_PASSWORD=$(cat $ROOT/config/config.json | jq -r ".zoo_password")

OUTPUT_GEN=$ROOT/secrets/generated/$ENVIRONMENT/$COLOUR
OUTPUT_ENV=$ROOT/secrets/environments/$ENVIRONMENT/$COLOUR

echo "Generating secrets for environment ${ENVIRONMENT} of colour ${COLOUR} into directory ${OUTPUT_ENV}"

if [ ! -d "$OUTPUT_GEN" ]; then

mkdir -p $OUTPUT_GEN

echo '[extended]\nextendedKeyUsage=serverAuth,clientAuth\nkeyUsage=digitalSignature,keyAgreement' > $OUTPUT_GEN/openssl.cnf

## Create certificate authority (CA)
openssl req -new -x509 -keyout $OUTPUT_GEN/ca_key.pem -out $OUTPUT_GEN/ca_cert.pem -days 365 -passin pass:secret -passout pass:secret -subj "/CN=myself"

## Create client keystore
keytool -noprompt -keystore $OUTPUT_GEN/keystore-client.jks -genkey -alias selfsigned -dname "CN=myself" -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 365 -storepass secret -keypass secret

## Create server keystore
keytool -noprompt -keystore $OUTPUT_GEN/keystore-server.jks -genkey -alias selfsigned -dname "CN=myself" -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 365 -storepass secret -keypass secret

## Create filebeat keystore
keytool -noprompt -keystore $OUTPUT_GEN/keystore-filebeat.jks -genkey -alias selfsigned -dname "CN=filebeat.service.${CONSUL_DATACENTER}.consul" -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 365 -storepass secret -keypass secret

## Create logstash keystore
keytool -noprompt -keystore $OUTPUT_GEN/keystore-kibana.jks -genkey -alias selfsigned -dname "CN=kibana.service.${CONSUL_DATACENTER}.consul" -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 365 -storepass secret -keypass secret

## Create logstash keystore
keytool -noprompt -keystore $OUTPUT_GEN/keystore-logstash.jks -genkey -alias selfsigned -dname "CN=logstash.service.${CONSUL_DATACENTER}.consul" -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 365 -storepass secret -keypass secret

## Create elasticsearch keystore
keytool -noprompt -keystore $OUTPUT_GEN/keystore-elasticsearch.jks -genkey -alias selfsigned -dname "CN=elasticsearch.service.${CONSUL_DATACENTER}.consul" -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 365 -storepass secret -keypass secret

## Create jenkins keystore
keytool -noprompt -keystore $OUTPUT_GEN/keystore-jenkins.jks -genkey -alias selfsigned -dname "CN=jenkins.service.${CONSUL_DATACENTER}.consul" -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 365 -storepass secret -keypass secret

## Create consul keystore
keytool -noprompt -keystore $OUTPUT_GEN/keystore-consul.jks -genkey -alias selfsigned -dname "CN=server.${CONSUL_DATACENTER}.consul" -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 365 -storepass secret -keypass secret

## Create openvpn certificate authority (CA)
openssl req -new -x509 -keyout $OUTPUT_GEN/openvpn_ca_key.pem -out $OUTPUT_GEN/openvpn_ca_cert.pem -days 365 -passin pass:secret -passout pass:secret -subj "/CN=openvpn"

## Create openvpn-server keystore
keytool -noprompt -keystore $OUTPUT_GEN/keystore-openvpn-server.jks -genkey -alias selfsigned -dname "CN=openvpn" -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 365 -storepass secret -keypass secret

## Create openvpn-client keystore
keytool -noprompt -keystore $OUTPUT_GEN/keystore-openvpn-client.jks -genkey -alias selfsigned -dname "CN=openvpn" -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 365 -storepass secret -keypass secret

## Sign client certificate
keytool -noprompt -keystore $OUTPUT_GEN/keystore-client.jks -alias selfsigned -certreq -file $OUTPUT_GEN/client_csr.pem -storepass secret
openssl x509 -extfile $OUTPUT_GEN/openssl.cnf -extensions extended -req -CA $OUTPUT_GEN/ca_cert.pem -CAkey $OUTPUT_GEN/ca_key.pem -in $OUTPUT_GEN/client_csr.pem -out $OUTPUT_GEN/client_cert.pem -days 365 -CAcreateserial -passin pass:secret

## Sign server certificate
keytool -noprompt -keystore $OUTPUT_GEN/keystore-server.jks -alias selfsigned -certreq -file $OUTPUT_GEN/server_csr.pem -storepass secret
openssl x509 -extfile $OUTPUT_GEN/openssl.cnf -extensions extended -req -CA $OUTPUT_GEN/ca_cert.pem -CAkey $OUTPUT_GEN/ca_key.pem -in $OUTPUT_GEN/server_csr.pem -out $OUTPUT_GEN/server_cert.pem -days 365 -CAcreateserial -passin pass:secret

## Sign filebeat certificate
keytool -noprompt -keystore $OUTPUT_GEN/keystore-filebeat.jks -alias selfsigned -certreq -file $OUTPUT_GEN/filebeat_csr.pem -storepass secret
openssl x509 -extfile $OUTPUT_GEN/openssl.cnf -extensions extended -req -CA $OUTPUT_GEN/ca_cert.pem -CAkey $OUTPUT_GEN/ca_key.pem -in $OUTPUT_GEN/filebeat_csr.pem -out $OUTPUT_GEN/filebeat_cert.pem -days 365 -CAcreateserial -passin pass:secret

## Sign kibana certificate
keytool -noprompt -keystore $OUTPUT_GEN/keystore-kibana.jks -alias selfsigned -certreq -file $OUTPUT_GEN/kibana_csr.pem -storepass secret
openssl x509 -extfile $OUTPUT_GEN/openssl.cnf -extensions extended -req -CA $OUTPUT_GEN/ca_cert.pem -CAkey $OUTPUT_GEN/ca_key.pem -in $OUTPUT_GEN/kibana_csr.pem -out $OUTPUT_GEN/kibana_cert.pem -days 365 -CAcreateserial -passin pass:secret

## Sign logstash certificate
keytool -noprompt -keystore $OUTPUT_GEN/keystore-logstash.jks -alias selfsigned -certreq -file $OUTPUT_GEN/logstash_csr.pem -storepass secret
openssl x509 -extfile $OUTPUT_GEN/openssl.cnf -extensions extended -req -CA $OUTPUT_GEN/ca_cert.pem -CAkey $OUTPUT_GEN/ca_key.pem -in $OUTPUT_GEN/logstash_csr.pem -out $OUTPUT_GEN/logstash_cert.pem -days 365 -CAcreateserial -passin pass:secret

## Sign elasticsearch certificate
keytool -noprompt -keystore $OUTPUT_GEN/keystore-elasticsearch.jks -alias selfsigned -certreq -file $OUTPUT_GEN/elasticsearch_csr.pem -storepass secret
openssl x509 -extfile $OUTPUT_GEN/openssl.cnf -extensions extended -req -CA $OUTPUT_GEN/ca_cert.pem -CAkey $OUTPUT_GEN/ca_key.pem -in $OUTPUT_GEN/elasticsearch_csr.pem -out $OUTPUT_GEN/elasticsearch_cert.pem -days 365 -CAcreateserial -passin pass:secret

## Sign consul certificate
keytool -noprompt -keystore $OUTPUT_GEN/keystore-consul.jks -alias selfsigned -certreq -file $OUTPUT_GEN/consul_csr.pem -storepass secret
openssl x509 -extfile $OUTPUT_GEN/openssl.cnf -extensions extended -req -CA $OUTPUT_GEN/ca_cert.pem -CAkey $OUTPUT_GEN/ca_key.pem -in $OUTPUT_GEN/consul_csr.pem -out $OUTPUT_GEN/consul_cert.pem -days 365 -CAcreateserial -passin pass:secret

## Sign openvpn-server certificate
keytool -noprompt -keystore $OUTPUT_GEN/keystore-openvpn-server.jks -alias selfsigned -certreq -file $OUTPUT_GEN/openvpn_server_csr.pem -storepass secret
openssl x509 -extfile $OUTPUT_GEN/openssl.cnf -extensions extended -req -CA $OUTPUT_GEN/openvpn_ca_cert.pem -CAkey $OUTPUT_GEN/openvpn_ca_key.pem -in $OUTPUT_GEN/openvpn_server_csr.pem -out $OUTPUT_GEN/openvpn_server_cert.pem -days 365 -CAcreateserial -passin pass:secret

## Sign openvpn-client certificate
keytool -noprompt -keystore $OUTPUT_GEN/keystore-openvpn-client.jks -alias selfsigned -certreq -file $OUTPUT_GEN/openvpn_client_csr.pem -storepass secret
openssl x509 -extfile $OUTPUT_GEN/openssl.cnf -extensions extended -req -CA $OUTPUT_GEN/openvpn_ca_cert.pem -CAkey $OUTPUT_GEN/openvpn_ca_key.pem -in $OUTPUT_GEN/openvpn_client_csr.pem -out $OUTPUT_GEN/openvpn_client_cert.pem -days 365 -CAcreateserial -passin pass:secret

## Import CA and client signed certificate into client keystore
keytool -noprompt -keystore $OUTPUT_GEN/keystore-client.jks -alias CARoot -import -file $OUTPUT_GEN/ca_cert.pem -storepass secret
keytool -noprompt -keystore $OUTPUT_GEN/keystore-client.jks -alias selfsigned -import -file $OUTPUT_GEN/client_cert.pem -storepass secret

## Import CA and server signed certificate into server keystore
keytool -noprompt -keystore $OUTPUT_GEN/keystore-server.jks -alias CARoot -import -file $OUTPUT_GEN/ca_cert.pem -storepass secret
keytool -noprompt -keystore $OUTPUT_GEN/keystore-server.jks -alias selfsigned -import -file $OUTPUT_GEN/server_cert.pem -storepass secret

## Import CA and filebeat signed certificate into filebeat keystore
keytool -noprompt -keystore $OUTPUT_GEN/keystore-filebeat.jks -alias CARoot -import -file $OUTPUT_GEN/ca_cert.pem -storepass secret
keytool -noprompt -keystore $OUTPUT_GEN/keystore-filebeat.jks -alias selfsigned -import -file $OUTPUT_GEN/filebeat_cert.pem -storepass secret

## Import CA and kibana signed certificate into kibana keystore
keytool -noprompt -keystore $OUTPUT_GEN/keystore-kibana.jks -alias CARoot -import -file $OUTPUT_GEN/ca_cert.pem -storepass secret
keytool -noprompt -keystore $OUTPUT_GEN/keystore-kibana.jks -alias selfsigned -import -file $OUTPUT_GEN/kibana_cert.pem -storepass secret

## Import CA and logstash signed certificate into logstash keystore
keytool -noprompt -keystore $OUTPUT_GEN/keystore-logstash.jks -alias CARoot -import -file $OUTPUT_GEN/ca_cert.pem -storepass secret
keytool -noprompt -keystore $OUTPUT_GEN/keystore-logstash.jks -alias selfsigned -import -file $OUTPUT_GEN/logstash_cert.pem -storepass secret

## Import CA and elasticsearch signed certificate into elasticsearch keystore
keytool -noprompt -keystore $OUTPUT_GEN/keystore-elasticsearch.jks -alias CARoot -import -file $OUTPUT_GEN/ca_cert.pem -storepass secret
keytool -noprompt -keystore $OUTPUT_GEN/keystore-elasticsearch.jks -alias selfsigned -import -file $OUTPUT_GEN/elasticsearch_cert.pem -storepass secret

## Import CA and consul signed certificate into consul keystore
keytool -noprompt -keystore $OUTPUT_GEN/keystore-consul.jks -alias CARoot -import -file $OUTPUT_GEN/ca_cert.pem -storepass secret
keytool -noprompt -keystore $OUTPUT_GEN/keystore-consul.jks -alias selfsigned -import -file $OUTPUT_GEN/consul_cert.pem -storepass secret

## Import CA and openvpn-server signed certificate into openvpn keystore
keytool -noprompt -keystore $OUTPUT_GEN/keystore-openvpn-server.jks -alias CARoot -import -file $OUTPUT_GEN/openvpn_ca_cert.pem -storepass secret
keytool -noprompt -keystore $OUTPUT_GEN/keystore-openvpn-server.jks -alias selfsigned -import -file $OUTPUT_GEN/openvpn_server_cert.pem -storepass secret

## Import CA and openvpn-client signed certificate into openvpn keystore
keytool -noprompt -keystore $OUTPUT_GEN/keystore-openvpn-client.jks -alias CARoot -import -file $OUTPUT_GEN/openvpn_ca_cert.pem -storepass secret
keytool -noprompt -keystore $OUTPUT_GEN/keystore-openvpn-client.jks -alias selfsigned -import -file $OUTPUT_GEN/openvpn_client_cert.pem -storepass secret

## Import CA into client truststore
keytool -noprompt -keystore $OUTPUT_GEN/truststore-client.jks -alias CARoot -import -file $OUTPUT_GEN/ca_cert.pem -storepass secret

## Import CA into server truststore
keytool -noprompt -keystore $OUTPUT_GEN/truststore-server.jks -alias CARoot -import -file $OUTPUT_GEN/ca_cert.pem -storepass secret

## Fetch Amazon CAs
curl -o $OUTPUT_GEN/AmazonRootCA1.pem https://www.amazontrust.com/repository/AmazonRootCA1.pem
curl -o $OUTPUT_GEN/AmazonRootCA2.pem https://www.amazontrust.com/repository/AmazonRootCA2.pem
curl -o $OUTPUT_GEN/AmazonRootCA3.pem https://www.amazontrust.com/repository/AmazonRootCA3.pem
curl -o $OUTPUT_GEN/AmazonRootCA4.pem https://www.amazontrust.com/repository/AmazonRootCA4.pem

## Import Amazon CAs into client truststore
keytool -noprompt -keystore $OUTPUT_GEN/truststore-client.jks -alias AmazonRootCA1 -import -file $OUTPUT_GEN/AmazonRootCA1.pem -storepass secret
keytool -noprompt -keystore $OUTPUT_GEN/truststore-client.jks -alias AmazonRootCA2 -import -file $OUTPUT_GEN/AmazonRootCA2.pem -storepass secret
keytool -noprompt -keystore $OUTPUT_GEN/truststore-client.jks -alias AmazonRootCA3 -import -file $OUTPUT_GEN/AmazonRootCA3.pem -storepass secret
keytool -noprompt -keystore $OUTPUT_GEN/truststore-client.jks -alias AmazonRootCA4 -import -file $OUTPUT_GEN/AmazonRootCA4.pem -storepass secret

## Import Amazon CAs into server truststore
keytool -noprompt -keystore $OUTPUT_GEN/truststore-server.jks -alias AmazonRootCA1 -import -file $OUTPUT_GEN/AmazonRootCA1.pem -storepass secret
keytool -noprompt -keystore $OUTPUT_GEN/truststore-server.jks -alias AmazonRootCA2 -import -file $OUTPUT_GEN/AmazonRootCA2.pem -storepass secret
keytool -noprompt -keystore $OUTPUT_GEN/truststore-server.jks -alias AmazonRootCA3 -import -file $OUTPUT_GEN/AmazonRootCA3.pem -storepass secret
keytool -noprompt -keystore $OUTPUT_GEN/truststore-server.jks -alias AmazonRootCA4 -import -file $OUTPUT_GEN/AmazonRootCA4.pem -storepass secret

## Create PEM files for NGINX, Logstash, Filebeat, Elasticsearch, Consul

### Extract signed client certificate
keytool -noprompt -keystore $OUTPUT_GEN/keystore-client.jks -exportcert -alias selfsigned -rfc -storepass secret -file $OUTPUT_GEN/client_cert.pem

### Extract client key
keytool -noprompt -srckeystore $OUTPUT_GEN/keystore-client.jks -importkeystore -srcalias selfsigned -destkeystore $OUTPUT_GEN/client_cert_and_key.p12 -deststoretype PKCS12 -srcstorepass secret -storepass secret
openssl pkcs12 -in $OUTPUT_GEN/client_cert_and_key.p12 -nocerts -nodes -passin pass:secret -out $OUTPUT_GEN/client_key.pem

### Extract signed server certificate
keytool -noprompt -keystore $OUTPUT_GEN/keystore-server.jks -exportcert -alias selfsigned -rfc -storepass secret -file $OUTPUT_GEN/server_cert.pem

### Extract server key
keytool -noprompt -srckeystore $OUTPUT_GEN/keystore-server.jks -importkeystore -srcalias selfsigned -destkeystore $OUTPUT_GEN/server_cert_and_key.p12 -deststoretype PKCS12 -srcstorepass secret -storepass secret
openssl pkcs12 -in $OUTPUT_GEN/server_cert_and_key.p12 -nocerts -nodes -passin pass:secret -out $OUTPUT_GEN/server_key.pem

### Extract signed filebeat certificate
keytool -noprompt -keystore $OUTPUT_GEN/keystore-filebeat.jks -exportcert -alias selfsigned -rfc -storepass secret -file $OUTPUT_GEN/filebeat_cert.pem

### Extract filebeat key
keytool -noprompt -srckeystore $OUTPUT_GEN/keystore-filebeat.jks -importkeystore -srcalias selfsigned -destkeystore $OUTPUT_GEN/filebeat_cert_and_key.p12 -deststoretype PKCS12 -srcstorepass secret -storepass secret
openssl pkcs12 -in $OUTPUT_GEN/filebeat_cert_and_key.p12 -nocerts -nodes -passin pass:secret -out $OUTPUT_GEN/filebeat_key.pem

### Extract signed kibana certificate
keytool -noprompt -keystore $OUTPUT_GEN/keystore-kibana.jks -exportcert -alias selfsigned -rfc -storepass secret -file $OUTPUT_GEN/kibana_cert.pem

### Extract kibana key
keytool -noprompt -srckeystore $OUTPUT_GEN/keystore-kibana.jks -importkeystore -srcalias selfsigned -destkeystore $OUTPUT_GEN/kibana_cert_and_key.p12 -deststoretype PKCS12 -srcstorepass secret -storepass secret
openssl pkcs12 -in $OUTPUT_GEN/kibana_cert_and_key.p12 -nocerts -nodes -passin pass:secret -out $OUTPUT_GEN/kibana_key.pem

### Extract signed logstash certificate
keytool -noprompt -keystore $OUTPUT_GEN/keystore-logstash.jks -exportcert -alias selfsigned -rfc -storepass secret -file $OUTPUT_GEN/logstash_cert.pem

### Extract logstash key
keytool -noprompt -srckeystore $OUTPUT_GEN/keystore-logstash.jks -importkeystore -srcalias selfsigned -destkeystore $OUTPUT_GEN/logstash_cert_and_key.p12 -deststoretype PKCS12 -srcstorepass secret -storepass secret
openssl pkcs12 -in $OUTPUT_GEN/logstash_cert_and_key.p12 -nocerts -nodes -passin pass:secret -out $OUTPUT_GEN/logstash_key.pem

### Extract signed elasticsearch certificate
keytool -noprompt -keystore $OUTPUT_GEN/keystore-elasticsearch.jks -exportcert -alias selfsigned -rfc -storepass secret -file $OUTPUT_GEN/elasticsearch_cert.pem

### Extract elasticsearch key
keytool -noprompt -srckeystore $OUTPUT_GEN/keystore-elasticsearch.jks -importkeystore -srcalias selfsigned -destkeystore $OUTPUT_GEN/elasticsearch_cert_and_key.p12 -deststoretype PKCS12 -srcstorepass secret -storepass secret
openssl pkcs12 -in $OUTPUT_GEN/elasticsearch_cert_and_key.p12 -nocerts -nodes -passin pass:secret -out $OUTPUT_GEN/elasticsearch_key.pem

### Extract signed consul certificate
keytool -noprompt -keystore $OUTPUT_GEN/keystore-consul.jks -exportcert -alias selfsigned -rfc -storepass secret -file $OUTPUT_GEN/consul_cert.pem

### Extract consul key
keytool -noprompt -srckeystore $OUTPUT_GEN/keystore-consul.jks -importkeystore -srcalias selfsigned -destkeystore $OUTPUT_GEN/consul_cert_and_key.p12 -deststoretype PKCS12 -srcstorepass secret -storepass secret
openssl pkcs12 -in $OUTPUT_GEN/consul_cert_and_key.p12 -nocerts -nodes -passin pass:secret -out $OUTPUT_GEN/consul_key.pem

### Extract signed openvpn-server certificate
keytool -noprompt -keystore $OUTPUT_GEN/keystore-openvpn-server.jks -exportcert -alias selfsigned -rfc -storepass secret -file $OUTPUT_GEN/openvpn_server_cert.pem

### Extract openvpn-server key
keytool -noprompt -srckeystore $OUTPUT_GEN/keystore-openvpn-server.jks -importkeystore -srcalias selfsigned -destkeystore $OUTPUT_GEN/openvpn_server_cert_and_key.p12 -deststoretype PKCS12 -srcstorepass secret -storepass secret
openssl pkcs12 -in $OUTPUT_GEN/openvpn_server_cert_and_key.p12 -nocerts -nodes -passin pass:secret -out $OUTPUT_GEN/openvpn_server_key.pem

### Extract signed openvpn-client certificate
keytool -noprompt -keystore $OUTPUT_GEN/keystore-openvpn-client.jks -exportcert -alias selfsigned -rfc -storepass secret -file $OUTPUT_GEN/openvpn_client_cert.pem

### Extract openvpn-client key
keytool -noprompt -srckeystore $OUTPUT_GEN/keystore-openvpn-client.jks -importkeystore -srcalias selfsigned -destkeystore $OUTPUT_GEN/openvpn_client_cert_and_key.p12 -deststoretype PKCS12 -srcstorepass secret -storepass secret
openssl pkcs12 -in $OUTPUT_GEN/openvpn_client_cert_and_key.p12 -nocerts -nodes -passin pass:secret -out $OUTPUT_GEN/openvpn_client_key.pem

### Extract openvpn CA certificate
keytool -noprompt -keystore $OUTPUT_GEN/keystore-openvpn-server.jks -exportcert -alias CARoot -rfc -storepass secret -file $OUTPUT_GEN/openvpn_ca_cert.pem

### Extract CA certificate
keytool -noprompt -keystore $OUTPUT_GEN/keystore-server.jks -exportcert -alias CARoot -rfc -storepass secret -file $OUTPUT_GEN/ca_cert.pem

### Copy keystores and truststores

cat $OUTPUT_GEN/client_cert.pem $OUTPUT_GEN/ca_cert.pem > $OUTPUT_GEN/ca_and_client_cert.pem
cat $OUTPUT_GEN/server_cert.pem $OUTPUT_GEN/ca_cert.pem > $OUTPUT_GEN/ca_and_server_cert.pem

openssl pkcs8 -in $OUTPUT_GEN/filebeat_key.pem -topk8 -inform PEM -nocrypt -out $OUTPUT_GEN/filebeat_key.pkcs8
openssl pkcs8 -in $OUTPUT_GEN/kibana_key.pem -topk8 -inform PEM -nocrypt -out $OUTPUT_GEN/kibana_key.pkcs8
openssl pkcs8 -in $OUTPUT_GEN/logstash_key.pem -topk8 -inform PEM -nocrypt -out $OUTPUT_GEN/logstash_key.pkcs8
openssl pkcs8 -in $OUTPUT_GEN/elasticsearch_key.pem -topk8 -inform PEM -nocrypt -out $OUTPUT_GEN/elasticsearch_key.pkcs8

openssl x509 -noout -text -in $OUTPUT_GEN/ca_cert.pem
openssl x509 -noout -text -in $OUTPUT_GEN/consul_cert.pem
openssl x509 -noout -text -in $OUTPUT_GEN/filebeat_cert.pem
openssl x509 -noout -text -in $OUTPUT_GEN/kibana_cert.pem
openssl x509 -noout -text -in $OUTPUT_GEN/logstash_cert.pem
openssl x509 -noout -text -in $OUTPUT_GEN/elasticsearch_cert.pem

openssl x509 -noout -text -in $OUTPUT_GEN/openvpn_ca_cert.pem
openssl x509 -noout -text -in $OUTPUT_GEN/openvpn_server_cert.pem
openssl x509 -noout -text -in $OUTPUT_GEN/openvpn_client_cert.pem

openssl dhparam -out $OUTPUT_GEN/openvpn_dh2048.pem 2048
openvpn --genkey --secret $OUTPUT_GEN/openvpn_ta.pem

cat <<EOF > $OUTPUT_GEN/client-ssl.properties
security.protocol=SSL
ssl.truststore.location=/secrets/truststore.jks
ssl.truststore.password=${PASSWORD}
ssl.keystore.location=/secrets/keystore.jks
ssl.keystore.password=${PASSWORD}
EOF

cat <<EOF > $OUTPUT_GEN/password_keystore.txt
${PASSWORD}
EOF

cat <<EOF > $OUTPUT_GEN/password_truststore.txt
${PASSWORD}
EOF

cat <<EOF > $OUTPUT_GEN/kafka_jaas.conf
Client {
       org.apache.zookeeper.server.auth.DigestLoginModule required
       username="kafka"
       password="${KAFKA_PASSWORD}";
};
EOF

cat <<EOF > $OUTPUT_GEN/zookeeper_jaas.conf
QuorumServer {
       org.apache.zookeeper.server.auth.DigestLoginModule required
       user_zookeeper="${ZOO_PASSWORD}";
};

QuorumLearner {
       org.apache.zookeeper.server.auth.DigestLoginModule required
       username="zookeeper"
       password="${ZOO_PASSWORD}";
};

Server {
       org.apache.zookeeper.server.auth.DigestLoginModule required
       user_kafka="${KAFKA_PASSWORD}";
};
EOF

else

echo "Secrets folder already exists. Just copying files..."

fi

### Copy certificates and keys

DST=$OUTPUT_ENV/keystores

mkdir -p $DST

cp $OUTPUT_GEN/keystore-client.jks $DST
cp $OUTPUT_GEN/keystore-server.jks $DST
cp $OUTPUT_GEN/truststore-client.jks $DST
cp $OUTPUT_GEN/truststore-server.jks $DST

DST=$OUTPUT_ENV/swarm

mkdir -p $DST

cp $OUTPUT_GEN/ca_cert.pem $DST
cp $OUTPUT_GEN/server_cert.pem $DST
cp $OUTPUT_GEN/server_key.pem $DST
cp $OUTPUT_GEN/client_cert.pem $DST
cp $OUTPUT_GEN/client_key.pem $DST

DST=$OUTPUT_ENV/kafka

mkdir -p $DST

cp $OUTPUT_GEN/keystore-client.jks $DST
cp $OUTPUT_GEN/keystore-server.jks $DST
cp $OUTPUT_GEN/truststore-client.jks $DST
cp $OUTPUT_GEN/truststore-server.jks $DST
cp $OUTPUT_GEN/password_keystore.txt $DST
cp $OUTPUT_GEN/password_truststore.txt $DST
cp $OUTPUT_GEN/client-ssl.properties $DST
cp $OUTPUT_GEN/kafka_jaas.conf $DST/client_jaas.conf

DST=$OUTPUT_ENV/zookeeper

mkdir -p $DST

cp $OUTPUT_GEN/zookeeper_jaas.conf $DST/server_jaas.conf

DST=$OUTPUT_ENV/nginx

mkdir -p $DST

cp $OUTPUT_GEN/ca_cert.pem $DST
cp $OUTPUT_GEN/server_cert.pem $DST
cp $OUTPUT_GEN/server_key.pem $DST
cp $OUTPUT_GEN/ca_and_server_cert.pem $DST

DST=$OUTPUT_ENV/filebeat

mkdir -p $DST

cp $OUTPUT_GEN/ca_cert.pem $DST
cp $OUTPUT_GEN/filebeat_cert.pem $DST
cp $OUTPUT_GEN/filebeat_key.pem $DST
cp $OUTPUT_GEN/filebeat_key.pkcs8 $DST

DST=$OUTPUT_ENV/kibana

mkdir -p $DST

cp $OUTPUT_GEN/ca_cert.pem $DST
cp $OUTPUT_GEN/kibana_cert.pem $DST
cp $OUTPUT_GEN/kibana_key.pem $DST
cp $OUTPUT_GEN/kibana_key.pkcs8 $DST

DST=$OUTPUT_ENV/logstash

mkdir -p $DST

cp $OUTPUT_GEN/ca_cert.pem $DST
cp $OUTPUT_GEN/logstash_cert.pem $DST
cp $OUTPUT_GEN/logstash_key.pem $DST
cp $OUTPUT_GEN/logstash_key.pkcs8 $DST

DST=$OUTPUT_ENV/elasticsearch

mkdir -p $DST

cp $OUTPUT_GEN/ca_cert.pem $DST
cp $OUTPUT_GEN/elasticsearch_cert.pem $DST
cp $OUTPUT_GEN/elasticsearch_key.pem $DST
cp $OUTPUT_GEN/elasticsearch_key.pkcs8 $DST

DST=$OUTPUT_ENV/consul

mkdir -p $DST

cp $OUTPUT_GEN/ca_cert.pem $DST
cp $OUTPUT_GEN/consul_cert.pem $DST/server_cert.pem
cp $OUTPUT_GEN/consul_key.pem $DST/server_key.pem

DST=$OUTPUT_ENV/jenkins

mkdir -p $DST

cp $OUTPUT_GEN/keystore-jenkins.jks $DST/keystore.jks

DST=$OUTPUT_ENV/openvpn

mkdir -p $DST

cp $OUTPUT_GEN/openvpn_ca_cert.pem $DST/ca_cert.pem
cp $OUTPUT_GEN/openvpn_server_cert.pem $DST/server_cert.pem
cp $OUTPUT_GEN/openvpn_server_key.pem $DST/server_key.pem
cp $OUTPUT_GEN/openvpn_client_cert.pem $DST/client_cert.pem
cp $OUTPUT_GEN/openvpn_client_key.pem $DST/client_key.pem
cp $OUTPUT_GEN/openvpn_dh2048.pem $DST/dh2048.pem
cp $OUTPUT_GEN/openvpn_ta.pem $DST/ta.pem
