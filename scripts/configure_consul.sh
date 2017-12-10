#!/bin/sh

export DIR=$ROOT

echo "Generating secret..."

export SECRET=$(docker run --rm -i consul:latest keygen)

echo "{\"consul_secret\":\"$SECRET\",\"consul_master_token\":\"b1gs33cr3t\"}" > $ROOT/config/consul.tfvars

echo "done."
