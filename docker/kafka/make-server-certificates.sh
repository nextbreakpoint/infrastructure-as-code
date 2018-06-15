#!/bin/sh

export PREFIX=$1
export NAME=$2
export KEYSTORE_PASSWORD=$3
export TRUSTSTORE_PASSWORD=$4
export CA_KEY_PASSWORD=$5
export CA_PREFIX=$6

if [ "$PREFIX" == "" ] ; then
  echo "Please provide a certificate prefix as first argument"
  exit 1
fi

if [ "$NAME" == "" ] ; then
  echo "Please provide the subject CN as second argument."
  exit 2
fi

if [ "$KEYSTORE_PASSWORD" == "" ] ; then
  echo "Please provide a keystore password as third argument"
  exit 3
fi

if [ "$TRUSTSTORE_PASSWORD" == "" ] ; then
  echo "Please provide a truststore password as fourth argument"
  exit 4
fi

if [ "$CA_KEY_PASSWORD" == "" ] ; then
  echo "Please provide a CA key password as fifth argument"
  exit 5
fi

if [ "$CA_PREFIX" == "" ] ; then
  echo "Please provide a CA certificate prefix as first argument"
  exit 6
fi

docker run --rm -it -v $(pwd)/secrets:/secrets openjdk:10-jre-slim bash -c " \
  keytool -noprompt -keystore /secrets/$PREFIX-server-keystore.jks -alias data-server-$PREFIX -dname \"CN=$NAME\" -storetype JKS -keyalg RSA -keysize 2048 -validity 365 -storepass $KEYSTORE_PASSWORD -keypass $KEYSTORE_PASSWORD -genkey \
  && keytool -noprompt -keystore /secrets/$PREFIX-server-truststore.jks -alias CARoot -import -file /secrets/$CA_PREFIX-ca-cert -storetype JKS -storepass $TRUSTSTORE_PASSWORD \
  && keytool -noprompt -keystore /secrets/$PREFIX-server-keystore.jks -alias data-server-$PREFIX -certreq -file /secrets/data-$PREFIX-server-cert-file -storepass $KEYSTORE_PASSWORD \
  && openssl x509 -req -CA /secrets/$CA_PREFIX-ca-cert -CAkey /secrets/$CA_PREFIX-ca-key -in /secrets/data-$PREFIX-server-cert-file -out /secrets/data-$PREFIX-server-cert-signed -days 365 -CAcreateserial -passin pass:$CA_KEY_PASSWORD \
  && keytool -noprompt -keystore /secrets/$PREFIX-server-keystore.jks -alias CARoot -import -file /secrets/$CA_PREFIX-ca-cert -storepass $KEYSTORE_PASSWORD \
  && keytool -noprompt -keystore /secrets/$PREFIX-server-keystore.jks -alias data-server-$PREFIX -import -file /secrets/data-$PREFIX-server-cert-signed -storepass $KEYSTORE_PASSWORD"
