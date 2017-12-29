#!/bin/sh

find . -name "tfplan" -exec rm {} \;
find . -name "*.tf.bkp" -exec rm {} \;
find . -name "*.tfbkp" -exec rm {} \;
find . -name "*.tf.backup" -exec rm {} \;
find . -name "*.tfstate.backup" -exec rm {} \;
find . -name ".terraform" -exec rm -fR {} \;

rm -fR terraform/secrets/environments secrets config/consult.tfvars config/network_vars.json
