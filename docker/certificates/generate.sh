#!/bin/sh

echo '[extended]\nextendedKeyUsage=serverAuth,clientAuth' > /output/openssl.cnf

## Create keystore for JWT authentication
keytool -genseckey -keystore /output/keystore-auth.jceks -storetype jceks -storepass secret -keyalg HMacSHA256 -keysize 2048 -alias HS256 -keypass secret
keytool -genseckey -keystore /output/keystore-auth.jceks -storetype jceks -storepass secret -keyalg HMacSHA384 -keysize 2048 -alias HS384 -keypass secret
keytool -genseckey -keystore /output/keystore-auth.jceks -storetype jceks -storepass secret -keyalg HMacSHA512 -keysize 2048 -alias HS512 -keypass secret
keytool -genkey -keystore /output/keystore-auth.jceks -storetype jceks -storepass secret -keyalg RSA -keysize 2048 -alias RS256 -keypass secret -sigalg SHA256withRSA -dname "CN=,OU=,O=,L=,ST=,C=" -validity 360
keytool -genkey -keystore /output/keystore-auth.jceks -storetype jceks -storepass secret -keyalg RSA -keysize 2048 -alias RS384 -keypass secret -sigalg SHA384withRSA -dname "CN=,OU=,O=,L=,ST=,C=" -validity 360
keytool -genkey -keystore /output/keystore-auth.jceks -storetype jceks -storepass secret -keyalg RSA -keysize 2048 -alias RS512 -keypass secret -sigalg SHA512withRSA -dname "CN=,OU=,O=,L=,ST=,C=" -validity 360
keytool -genkeypair -keystore /output/keystore-auth.jceks -storetype jceks -storepass secret -keyalg EC -keysize 256 -alias ES256 -keypass secret -sigalg SHA256withECDSA -dname "CN=,OU=,O=,L=,ST=,C=" -validity 360
keytool -genkeypair -keystore /output/keystore-auth.jceks -storetype jceks -storepass secret -keyalg EC -keysize 256 -alias ES384 -keypass secret -sigalg SHA384withECDSA -dname "CN=,OU=,O=,L=,ST=,C=" -validity 360
keytool -genkeypair -keystore /output/keystore-auth.jceks -storetype jceks -storepass secret -keyalg EC -keysize 256 -alias ES512 -keypass secret -sigalg SHA512withECDSA -dname "CN=,OU=,O=,L=,ST=,C=" -validity 360

## Create certificate authority (CA)
openssl req -new -x509 -keyout /output/ca-key -out /output/ca-cert -days 365 -passin pass:secret -passout pass:secret -subj "/CN=myself/OU=/O=/L=/ST=/C=/"

## Create client keystore
keytool -noprompt -keystore /output/keystore-client.jks -genkey -alias selfsigned -dname "CN=myself,OU=,O=,L=,ST=,C=" -storetype JKS -keyalg RSA -keysize 2048 -validity 999 -storepass secret -keypass secret

## Create server keystore
keytool -noprompt -keystore /output/keystore-server.jks -genkey -alias selfsigned -dname "CN=myself,OU=,O=,L=,ST=,C=" -storetype JKS -keyalg RSA -keysize 2048 -validity 999 -storepass secret -keypass secret

## Create filebeat keystore
keytool -noprompt -keystore /output/keystore-filebeat.jks -genkey -alias selfsigned -dname "CN=filebeat,OU=,O=,L=,ST=,C=" -storetype JKS -keyalg RSA -keysize 2048 -validity 999 -storepass secret -keypass secret

## Create logstash keystore
keytool -noprompt -keystore /output/keystore-logstash.jks -genkey -alias selfsigned -dname "CN=logstash.internal,OU=,O=,L=,ST=,C=" -storetype JKS -keyalg RSA -keysize 2048 -validity 999 -storepass secret -keypass secret

## Create elasticsearch keystore
keytool -noprompt -keystore /output/keystore-elasticsearch.jks -genkey -alias selfsigned -dname "CN=elasticsearch.internal,OU=,O=,L=,ST=,C=" -storetype JKS -keyalg RSA -keysize 2048 -validity 999 -storepass secret -keypass secret

## Create consul keystore
keytool -noprompt -keystore /output/keystore-consul.jks -genkey -alias selfsigned -dname "CN=server.terraform.consul,OU=,O=,L=,ST=,C=" -storetype JKS -keyalg RSA -keysize 2048 -validity 999 -storepass secret -keypass secret

## Sign client certificate
keytool -noprompt -keystore /output/keystore-client.jks -alias selfsigned -certreq -file /output/client.unsigned -storepass secret
openssl x509 -extfile /output/openssl.cnf -extensions extended -req -CA /output/ca-cert -CAkey /output/ca-key -in /output/client.unsigned -out /output/client.signed -days 365 -CAcreateserial -passin pass:secret

## Sign server certificate
keytool -noprompt -keystore /output/keystore-server.jks -alias selfsigned -certreq -file /output/server.unsigned -storepass secret
openssl x509 -extfile /output/openssl.cnf -extensions extended -req -CA /output/ca-cert -CAkey /output/ca-key -in /output/server.unsigned -out /output/server.signed -days 365 -CAcreateserial -passin pass:secret

## Sign filebeat certificate
keytool -noprompt -keystore /output/keystore-filebeat.jks -alias selfsigned -certreq -file /output/filebeat.unsigned -storepass secret
openssl x509 -extfile /output/openssl.cnf -extensions extended -req -CA /output/ca-cert -CAkey /output/ca-key -in /output/filebeat.unsigned -out /output/filebeat.signed -days 365 -CAcreateserial -passin pass:secret

## Sign logstash certificate
keytool -noprompt -keystore /output/keystore-logstash.jks -alias selfsigned -certreq -file /output/logstash.unsigned -storepass secret
openssl x509 -extfile /output/openssl.cnf -extensions extended -req -CA /output/ca-cert -CAkey /output/ca-key -in /output/logstash.unsigned -out /output/logstash.signed -days 365 -CAcreateserial -passin pass:secret

## Sign elasticsearch certificate
keytool -noprompt -keystore /output/keystore-elasticsearch.jks -alias selfsigned -certreq -file /output/elasticsearch.unsigned -storepass secret
openssl x509 -extfile /output/openssl.cnf -extensions extended -req -CA /output/ca-cert -CAkey /output/ca-key -in /output/elasticsearch.unsigned -out /output/elasticsearch.signed -days 365 -CAcreateserial -passin pass:secret

## Sign consul certificate
keytool -noprompt -keystore /output/keystore-consul.jks -alias selfsigned -certreq -file /output/consul.unsigned -storepass secret
openssl x509 -extfile /output/openssl.cnf -extensions extended -req -CA /output/ca-cert -CAkey /output/ca-key -in /output/consul.unsigned -out /output/consul.signed -days 365 -CAcreateserial -passin pass:secret

## Import CA and client signed certificate into client keystore
keytool -noprompt -keystore /output/keystore-client.jks -alias CARoot -import -file /output/ca-cert  -storepass secret
keytool -noprompt -keystore /output/keystore-client.jks -alias selfsigned -import -file /output/client.signed -storepass secret

## Import CA and server signed certificate into server keystore
keytool -noprompt -keystore /output/keystore-server.jks -alias CARoot -import -file /output/ca-cert  -storepass secret
keytool -noprompt -keystore /output/keystore-server.jks -alias selfsigned -import -file /output/server.signed -storepass secret

## Import CA and filebeat signed certificate into filebeat keystore
keytool -noprompt -keystore /output/keystore-filebeat.jks -alias CARoot -import -file /output/ca-cert  -storepass secret
keytool -noprompt -keystore /output/keystore-filebeat.jks -alias selfsigned -import -file /output/filebeat.signed -storepass secret

## Import CA and logstash signed certificate into logstash keystore
keytool -noprompt -keystore /output/keystore-logstash.jks -alias CARoot -import -file /output/ca-cert  -storepass secret
keytool -noprompt -keystore /output/keystore-logstash.jks -alias selfsigned -import -file /output/logstash.signed -storepass secret

## Import CA and elasticsearch signed certificate into elasticsearch keystore
keytool -noprompt -keystore /output/keystore-elasticsearch.jks -alias CARoot -import -file /output/ca-cert  -storepass secret
keytool -noprompt -keystore /output/keystore-elasticsearch.jks -alias selfsigned -import -file /output/elasticsearch.signed -storepass secret

## Import CA and consul signed certificate into consul keystore
keytool -noprompt -keystore /output/keystore-consul.jks -alias CARoot -import -file /output/ca-cert  -storepass secret
keytool -noprompt -keystore /output/keystore-consul.jks -alias selfsigned -import -file /output/consul.signed -storepass secret

## Import CA into client truststore
keytool -noprompt -keystore /output/truststore-client.jks -alias CARoot -import -file /output/ca-cert -storepass secret

## Import CA into server truststore
keytool -noprompt -keystore /output/truststore-server.jks -alias CARoot -import -file /output/ca-cert -storepass secret

## Create PEM files for NGINX, Logstash, Filebeat, Elasticsearch, Consul

### Extract signed client certificate
keytool -noprompt -keystore /output/keystore-client.jks -exportcert -alias selfsigned -rfc -storepass secret -file /output/client_cert.pem

### Extract client key
keytool -noprompt -srckeystore /output/keystore-client.jks -importkeystore -srcalias selfsigned -destkeystore /output/client_cert_and_key.p12 -deststoretype PKCS12 -srcstorepass secret -storepass secret
openssl pkcs12 -in /output/client_cert_and_key.p12 -nocerts -nodes -passin pass:secret -out /output/client_key.pem

### Extract signed server certificate
keytool -noprompt -keystore /output/keystore-server.jks -exportcert -alias selfsigned -rfc -storepass secret -file /output/server_cert.pem

### Extract server key
keytool -noprompt -srckeystore /output/keystore-server.jks -importkeystore -srcalias selfsigned -destkeystore /output/server_cert_and_key.p12 -deststoretype PKCS12 -srcstorepass secret -storepass secret
openssl pkcs12 -in /output/server_cert_and_key.p12 -nocerts -nodes -passin pass:secret -out /output/server_key.pem

### Extract signed filebeat certificate
keytool -noprompt -keystore /output/keystore-filebeat.jks -exportcert -alias selfsigned -rfc -storepass secret -file /output/filebeat_cert.pem

### Extract filebeat key
keytool -noprompt -srckeystore /output/keystore-filebeat.jks -importkeystore -srcalias selfsigned -destkeystore /output/filebeat_cert_and_key.p12 -deststoretype PKCS12 -srcstorepass secret -storepass secret
openssl pkcs12 -in /output/filebeat_cert_and_key.p12 -nocerts -nodes -passin pass:secret -out /output/filebeat_key.pem

### Extract signed logstash certificate
keytool -noprompt -keystore /output/keystore-logstash.jks -exportcert -alias selfsigned -rfc -storepass secret -file /output/logstash_cert.pem

### Extract logstash key
keytool -noprompt -srckeystore /output/keystore-logstash.jks -importkeystore -srcalias selfsigned -destkeystore /output/logstash_cert_and_key.p12 -deststoretype PKCS12 -srcstorepass secret -storepass secret
openssl pkcs12 -in /output/logstash_cert_and_key.p12 -nocerts -nodes -passin pass:secret -out /output/logstash_key.pem

### Extract signed elasticsearch certificate
keytool -noprompt -keystore /output/keystore-elasticsearch.jks -exportcert -alias selfsigned -rfc -storepass secret -file /output/elasticsearch_cert.pem

### Extract elasticsearch key
keytool -noprompt -srckeystore /output/keystore-elasticsearch.jks -importkeystore -srcalias selfsigned -destkeystore /output/elasticsearch_cert_and_key.p12 -deststoretype PKCS12 -srcstorepass secret -storepass secret
openssl pkcs12 -in /output/elasticsearch_cert_and_key.p12 -nocerts -nodes -passin pass:secret -out /output/elasticsearch_key.pem

### Extract signed consul certificate
keytool -noprompt -keystore /output/keystore-consul.jks -exportcert -alias selfsigned -rfc -storepass secret -file /output/consul_cert.pem

### Extract consul key
keytool -noprompt -srckeystore /output/keystore-consul.jks -importkeystore -srcalias selfsigned -destkeystore /output/consul_cert_and_key.p12 -deststoretype PKCS12 -srcstorepass secret -storepass secret
openssl pkcs12 -in /output/consul_cert_and_key.p12 -nocerts -nodes -passin pass:secret -out /output/consul_key.pem

### Extract CA certificate
keytool -noprompt -keystore /output/keystore-server.jks -exportcert -alias CARoot -rfc -storepass secret -file /output/ca_cert.pem

### Copy keystores and truststores

cat /output/client_cert.pem /output/ca_cert.pem > /output/ca_and_client_cert.pem
cat /output/server_cert.pem /output/ca_cert.pem > /output/ca_and_server_cert.pem

openssl pkcs8 -in /output/filebeat_key.pem -topk8 -inform PEM -nocrypt -out /output/filebeat_key.pkcs8
openssl pkcs8 -in /output/logstash_key.pem -topk8 -inform PEM -nocrypt -out /output/logstash_key.pkcs8
openssl pkcs8 -in /output/elasticsearch_key.pem -topk8 -inform PEM -nocrypt -out /output/elasticsearch_key.pkcs8

openssl x509 -noout -text -in /output/consul_cert.pem
openssl x509 -noout -text -in /output/filebeat_cert.pem
openssl x509 -noout -text -in /output/logstash_cert.pem
openssl x509 -noout -text -in /output/elasticsearch_cert.pem
