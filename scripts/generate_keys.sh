#!/bin/sh

KEYFILE=$ROOT/deployer_key.pem

if [ ! -f "$KEYFILE" ]; then

  ssh-keygen -b 2048 -t rsa -N "" -f $KEYFILE

  chmod 600 $KEYFILE

else

  echo "Deployer key already exists. Skipping!"

fi
