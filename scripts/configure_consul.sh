#!/bin/sh

echo "Generating secret..."

SECRET=$(consul keygen)

echo "{\"consul_secret\":\"$SECRET\",\"consul_master_token\":\"b1gs33cr3t\"}" > $ROOT/config/consul.tfvars

echo "done."
