#!/bin/bash
export DIR=secrets

rm -fR $DIR

mkdir -p $DIR

## Create keystore for JWT authentication
keytool -genseckey -keystore $DIR/keystore-auth.jceks -storetype jceks -storepass secret -keyalg HMacSHA256 -keysize 2048 -alias HS256 -keypass secret
keytool -genseckey -keystore $DIR/keystore-auth.jceks -storetype jceks -storepass secret -keyalg HMacSHA384 -keysize 2048 -alias HS384 -keypass secret
keytool -genseckey -keystore $DIR/keystore-auth.jceks -storetype jceks -storepass secret -keyalg HMacSHA512 -keysize 2048 -alias HS512 -keypass secret
keytool -genkey -keystore $DIR/keystore-auth.jceks -storetype jceks -storepass secret -keyalg RSA -keysize 2048 -alias RS256 -keypass secret -sigalg SHA256withRSA -dname "CN=,OU=,O=,L=,ST=,C=" -validity 360
keytool -genkey -keystore $DIR/keystore-auth.jceks -storetype jceks -storepass secret -keyalg RSA -keysize 2048 -alias RS384 -keypass secret -sigalg SHA384withRSA -dname "CN=,OU=,O=,L=,ST=,C=" -validity 360
keytool -genkey -keystore $DIR/keystore-auth.jceks -storetype jceks -storepass secret -keyalg RSA -keysize 2048 -alias RS512 -keypass secret -sigalg SHA512withRSA -dname "CN=,OU=,O=,L=,ST=,C=" -validity 360
keytool -genkeypair -keystore $DIR/keystore-auth.jceks -storetype jceks -storepass secret -keyalg EC -keysize 256 -alias ES256 -keypass secret -sigalg SHA256withECDSA -dname "CN=,OU=,O=,L=,ST=,C=" -validity 360
keytool -genkeypair -keystore $DIR/keystore-auth.jceks -storetype jceks -storepass secret -keyalg EC -keysize 256 -alias ES384 -keypass secret -sigalg SHA384withECDSA -dname "CN=,OU=,O=,L=,ST=,C=" -validity 360
keytool -genkeypair -keystore $DIR/keystore-auth.jceks -storetype jceks -storepass secret -keyalg EC -keysize 256 -alias ES512 -keypass secret -sigalg SHA512withECDSA -dname "CN=,OU=,O=,L=,ST=,C=" -validity 360

## Create certificate authority (CA)
openssl req -new -x509 -keyout $DIR/ca-key -out $DIR/ca-cert -days 365 -passin pass:secret -passout pass:secret -subj "/CN=myself/OU=/O=/L=/ST=/C=/"

## Create client keystore
keytool -noprompt -keystore $DIR/keystore-client.jks -genkey -alias selfsigned -dname "CN=myself,OU=,O=,L=,ST=,C=" -storetype JKS -keyalg RSA -keysize 2048 -validity 999 -storepass secret -keypass secret

## Create server keystore
keytool -noprompt -keystore $DIR/keystore-server.jks -genkey -alias selfsigned -dname "CN=myself,OU=,O=,L=,ST=,C=" -storetype JKS -keyalg RSA -keysize 2048 -validity 999 -storepass secret -keypass secret

## Sign client certificate
keytool -noprompt -keystore $DIR/keystore-client.jks -alias selfsigned -certreq -file $DIR/client.unsigned -storepass secret
openssl x509 -req -CA $DIR/ca-cert -CAkey $DIR/ca-key -in $DIR/client.unsigned -out $DIR/client.signed -days 365 -CAcreateserial -passin pass:secret

## Sign server certificate
keytool -noprompt -keystore $DIR/keystore-server.jks -alias selfsigned -certreq -file $DIR/server.unsigned -storepass secret
openssl x509 -req -CA $DIR/ca-cert -CAkey $DIR/ca-key -in $DIR/server.unsigned -out $DIR/server.signed -days 365 -CAcreateserial -passin pass:secret

## Import CA and client signed certificate into client keystore
keytool -noprompt -keystore $DIR/keystore-client.jks -alias CARoot -import -file $DIR/ca-cert  -storepass secret
keytool -noprompt -keystore $DIR/keystore-client.jks -alias selfsigned -import -file $DIR/client.signed -storepass secret

## Import CA and server signed certificate into server keystore
keytool -noprompt -keystore $DIR/keystore-server.jks -alias CARoot -import -file $DIR/ca-cert  -storepass secret
keytool -noprompt -keystore $DIR/keystore-server.jks -alias selfsigned -import -file $DIR/server.signed -storepass secret

## Import CA into client truststore
keytool -noprompt -keystore $DIR/truststore-client.jks -alias CARoot -import -file $DIR/ca-cert -storepass secret

## Import CA into server truststore
keytool -noprompt -keystore $DIR/truststore-server.jks -alias CARoot -import -file $DIR/ca-cert -storepass secret

## Create PEM files for NGINX, Logstash and Filebeat

### Extract signed client certificate
keytool -noprompt -keystore $DIR/keystore-client.jks -exportcert -alias selfsigned -rfc -storepass secret -file $DIR/client_cert.pem

### Extract client key
keytool -noprompt -srckeystore $DIR/keystore-client.jks -importkeystore -srcalias selfsigned -destkeystore $DIR/client_cert_and_key.p12 -deststoretype PKCS12 -srcstorepass secret -storepass secret
openssl pkcs12 -in $DIR/client_cert_and_key.p12 -nocerts -nodes -passin pass:secret -out $DIR/client_key.pem

### Extract signed server certificate
keytool -noprompt -keystore $DIR/keystore-server.jks -exportcert -alias selfsigned -rfc -storepass secret -file $DIR/server_cert.pem

### Extract server key
keytool -noprompt -srckeystore $DIR/keystore-server.jks -importkeystore -srcalias selfsigned -destkeystore $DIR/server_cert_and_key.p12 -deststoretype PKCS12 -srcstorepass secret -storepass secret
openssl pkcs12 -in $DIR/server_cert_and_key.p12 -nocerts -nodes -passin pass:secret -out $DIR/server_key.pem

### Extract CA certificate
keytool -noprompt -keystore $DIR/keystore-server.jks -exportcert -alias CARoot -rfc -storepass secret -file $DIR/ca_cert.pem

### Copy keystores and truststores

cat $DIR/client_cert.pem $DIR/ca_cert.pem > $DIR/ca_and_client_cert.pem
cat $DIR/server_cert.pem $DIR/ca_cert.pem > $DIR/ca_and_server_cert.pem

openssl pkcs8 -in $DIR/server_key.pem -topk8 -inform PEM -nocrypt -out $DIR/server_key.pkcs8
openssl pkcs8 -in $DIR/client_key.pem -topk8 -inform PEM -nocrypt -out $DIR/client_key.pkcs8

export DST=terraform/secrets/environments/production/keystores

mkdir -p $DST

cp $DIR/keystore-auth.jceks $DST
cp $DIR/keystore-client.jks $DST
cp $DIR/keystore-server.jks $DST
cp $DIR/truststore-client.jks $DST
cp $DIR/truststore-server.jks $DST

### Copy certificates and keys

export DST=terraform/secrets/environments/production/nginx

mkdir -p $DST

cp $DIR/ca_cert.pem $DST
cp $DIR/server_cert.pem $DST
cp $DIR/server_key.pem $DST
cp $DIR/ca_and_server_cert.pem $DST

export DST=terraform/secrets/environments/production/logstash

mkdir -p $DST

cp $DIR/ca_cert.pem $DST
cp $DIR/server_cert.pem $DST
cp $DIR/server_key.pem $DST
cp $DIR/server_key.pkcs8 $DST

export DST=terraform/secrets/environments/production/filebeat

mkdir -p $DST

cp $DIR/ca_cert.pem $DST
cp $DIR/client_cert.pem $DST
cp $DIR/client_key.pem $DST
cp $DIR/client_key.pkcs8 $DST

docker build -t configure-consul docker/consul/.
docker run --rm -t -v $(pwd)/$DIR:/output configure-consul
docker run --rm -t -v $(pwd)/$DIR:/output configure-consul openssl x509 -noout -text -in /output/consul_server_cert.pem

export DST=terraform/secrets/environments/production/consul

mkdir -p $DST

cp $DIR/consul_ca_cert.pem $DST/ca_cert.pem
cp $DIR/consul_server_cert.pem $DST/server_cert.pem
cp $DIR/consul_server_key.pem $DST/server_key.pem
