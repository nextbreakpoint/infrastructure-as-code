#!/bin/bash
DIR=$(pwd)

export SECRET=$(docker run --rm -i consul:latest keygen)

echo "{\"consul_secret\":\"$SECRET\",\"consul_master_token\":\"b1gs33cr3t\"}" > consul.tfvars
