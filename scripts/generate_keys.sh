#!/bin/sh

ENVIRONMENT=$(cat $ROOT/config/main.json | jq -r ".environment")
COLOUR=$(cat $ROOT/config/main.json | jq -r ".colour")
KEY_NAME=$(cat $ROOT/config/misc.json | jq -r ".key_name")

KEYFILE=$ROOT/${ENVIRONMENT}-${COLOUR}-${KEY_NAME}.pem

if [ ! -f "$KEYFILE" ]; then

  ssh-keygen -b 2048 -t rsa -N "" -f $KEYFILE

  chmod 600 $KEYFILE

else

  echo "Deployer key already exists. Skipping!"

fi
