#!/bin/bash
DIR=$(pwd)

export SECRET=$(docker run -i consul:latest keygen)

echo "{\"consul_secret\":\"$SECRET\"}" > consul.tfvars
