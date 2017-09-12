#!/bin/bash
DIR=$(pwd)
source bash_alias

# Create VPC and subnets
cd $DIR/terraform/vpc && tf_init && tf_apply

# Create bastion server
cd $DIR/terraform/bastion && tf_init && tf_apply

# Create network routing rules
cd $DIR/terraform/network && tf_init && tf_apply
