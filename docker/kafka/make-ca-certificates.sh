#!/bin/sh

export PREFIX=$1
export NAME=$2
export CA_KEY_PASSWORD=$3

if [ "$PREFIX" == "" ] ; then
  echo "Please provide a certificate prefix as first argument"
  exit 1
fi

if [ "$NAME" == "" ] ; then
  echo "Please provide the subject CN as second argument."
  exit 2
fi

if [ "$CA_KEY_PASSWORD" == "" ] ; then
  echo "Please provide a CA key password as third argument"
  exit 3
fi

docker run --rm -it -v $(pwd)/secrets:/secrets openjdk:10-jre-slim bash -c " \
  openssl req -new -x509 -keyout /secrets/$PREFIX-ca-key -out /secrets/$PREFIX-ca-cert -days 365 -passin pass:$CA_KEY_PASSWORD -passout pass:$CA_KEY_PASSWORD -subj \"/CN=$NAME\""
