#!/bin/sh

. $ROOT/bash_aliases

# Create VPC and subnets
cd $ROOT/terraform/vpc && tf_init && tf_plan && tf_apply
