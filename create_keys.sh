#!/bin/bash
DIR=$(pwd)
source bash_alias

rm deployer_key.*

ssh-keygen -b 2048 -t rsa -N password -f deployer_key.pem

chmod 600 deployer_key.pem

cd $DIR/terraform/keys && tf_init && tf_apply

cd $DIR/terraform/keys && terraform output -json
