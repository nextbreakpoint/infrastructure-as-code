#!/bin/sh

HOSTED_ZONE_NAME=
ENVIRONMENT=
COLOUR=

KEY_PASSWORD=
KEYSTORE_PASSWORD=
TRUSTSTORE_PASSWORD=

OUTPUT_GEN=$ROOT/secrets/generated/$ENVIRONMENT/$COLOUR
OUTPUT_ENV=$ROOT/secrets/environments/$ENVIRONMENT/$COLOUR

echo "Generating secrets for environment ${ENVIRONMENT} of colour ${COLOUR} into directory ${OUTPUT_ENV}"

if [ ! -d "$OUTPUT_GEN" ]; then

mkdir -p $OUTPUT_GEN

echo '[extended]\nextendedKeyUsage=serverAuth,clientAuth\nkeyUsage=digitalSignature,keyAgreement' > $OUTPUT_GEN/openssl.cnf

## Create certificate authority (CA)
openssl req -new -x509 -keyout $OUTPUT_GEN/ca_key.pem -out $OUTPUT_GEN/ca_cert.pem -days 365 -passin pass:$KEY_PASSWORD -passout pass:$KEY_PASSWORD -subj "/CN=${HOSTED_ZONE_NAME}"

## Create client keystore
keytool -noprompt -keystore $OUTPUT_GEN/keystore-client.jks -genkey -alias selfsigned -dname "CN=${HOSTED_ZONE_NAME}" -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 365 -storepass $KEYSTORE_PASSWORD -keypass $KEY_PASSWORD

## Create server keystore
keytool -noprompt -keystore $OUTPUT_GEN/keystore-server.jks -genkey -alias selfsigned -dname "CN=${HOSTED_ZONE_NAME}" -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 365 -storepass $KEYSTORE_PASSWORD -keypass $KEY_PASSWORD

## Sign client certificate
keytool -noprompt -keystore $OUTPUT_GEN/keystore-client.jks -alias selfsigned -certreq -file $OUTPUT_GEN/client_csr.pem -storepass $KEYSTORE_PASSWORD
openssl x509 -extfile $OUTPUT_GEN/openssl.cnf -extensions extended -req -CA $OUTPUT_GEN/ca_cert.pem -CAkey $OUTPUT_GEN/ca_key.pem -in $OUTPUT_GEN/client_csr.pem -out $OUTPUT_GEN/client_cert.pem -days 365 -CAcreateserial -passin pass:$KEYSTORE_PASSWORD

## Sign server certificate
keytool -noprompt -keystore $OUTPUT_GEN/keystore-server.jks -alias selfsigned -certreq -file $OUTPUT_GEN/server_csr.pem -storepass $KEYSTORE_PASSWORD
openssl x509 -extfile $OUTPUT_GEN/openssl.cnf -extensions extended -req -CA $OUTPUT_GEN/ca_cert.pem -CAkey $OUTPUT_GEN/ca_key.pem -in $OUTPUT_GEN/server_csr.pem -out $OUTPUT_GEN/server_cert.pem -days 365 -CAcreateserial -passin pass:$KEYSTORE_PASSWORD

## Import CA and client signed certificate into client keystore
keytool -noprompt -keystore $OUTPUT_GEN/keystore-client.jks -alias CARoot -import -file $OUTPUT_GEN/ca_cert.pem -storepass $KEYSTORE_PASSWORD
keytool -noprompt -keystore $OUTPUT_GEN/keystore-client.jks -alias selfsigned -import -file $OUTPUT_GEN/client_cert.pem -storepass $KEYSTORE_PASSWORD

## Import CA and server signed certificate into server keystore
keytool -noprompt -keystore $OUTPUT_GEN/keystore-server.jks -alias CARoot -import -file $OUTPUT_GEN/ca_cert.pem -storepass $KEYSTORE_PASSWORD
keytool -noprompt -keystore $OUTPUT_GEN/keystore-server.jks -alias selfsigned -import -file $OUTPUT_GEN/server_cert.pem -storepass $KEYSTORE_PASSWORD

## Import CA into client truststore
keytool -noprompt -keystore $OUTPUT_GEN/truststore-client.jks -alias CARoot -import -file $OUTPUT_GEN/ca_cert.pem -storepass $TRUSTSTORE_PASSWORD

## Import CA into server truststore
keytool -noprompt -keystore $OUTPUT_GEN/truststore-server.jks -alias CARoot -import -file $OUTPUT_GEN/ca_cert.pem -storepass $TRUSTSTORE_PASSWORD

### Extract signed client certificate
keytool -noprompt -keystore $OUTPUT_GEN/keystore-client.jks -exportcert -alias selfsigned -rfc -storepass $KEYSTORE_PASSWORD -file $OUTPUT_GEN/client_cert.pem

### Extract client key
keytool -noprompt -srckeystore $OUTPUT_GEN/keystore-client.jks -importkeystore -srcalias selfsigned -destkeystore $OUTPUT_GEN/client_cert_and_key.p12 -deststoretype PKCS12 -srcstorepass $KEYSTORE_PASSWORD -storepass $KEYSTORE_PASSWORD
openssl pkcs12 -in $OUTPUT_GEN/client_cert_and_key.p12 -nocerts -nodes -passin pass:$KEYSTORE_PASSWORD -out $OUTPUT_GEN/client_key.pem

### Extract signed server certificate
keytool -noprompt -keystore $OUTPUT_GEN/keystore-server.jks -exportcert -alias selfsigned -rfc -storepass $KEYSTORE_PASSWORD -file $OUTPUT_GEN/server_cert.pem

### Extract server key
keytool -noprompt -srckeystore $OUTPUT_GEN/keystore-server.jks -importkeystore -srcalias selfsigned -destkeystore $OUTPUT_GEN/server_cert_and_key.p12 -deststoretype PKCS12 -srcstorepass $KEYSTORE_PASSWORD -storepass $KEYSTORE_PASSWORD
openssl pkcs12 -in $OUTPUT_GEN/server_cert_and_key.p12 -nocerts -nodes -passin pass:$KEYSTORE_PASSWORD -out $OUTPUT_GEN/server_key.pem

### Extract CA certificate
keytool -noprompt -keystore $OUTPUT_GEN/keystore-server.jks -exportcert -alias CARoot -rfc -storepass $KEYSTORE_PASSWORD -file $OUTPUT_GEN/ca_cert.pem

### Copy keystores and truststores

cat $OUTPUT_GEN/client_cert.pem $OUTPUT_GEN/ca_cert.pem > $OUTPUT_GEN/ca_and_client_cert.pem
cat $OUTPUT_GEN/server_cert.pem $OUTPUT_GEN/ca_cert.pem > $OUTPUT_GEN/ca_and_server_cert.pem

openssl x509 -noout -text -in $OUTPUT_GEN/ca_cert.pem

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
