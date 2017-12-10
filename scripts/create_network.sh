#!/bin/sh

. $ROOT/bash_aliases

export DIR=$ROOT

# Create VPC and subnets
cd $DIR/terraform/vpc && tf_init && tf_plan && tf_apply

# Create network routing tables and NAT boxes
cd $DIR/terraform/network && tf_init && tf_plan && tf_apply

# Create bastion server
cd $DIR/terraform/bastion && tf_init && tf_plan && tf_apply &
bastion_pid=$!

# Create openvpn server
cd $DIR/terraform/openvpn && tf_init && tf_plan && tf_apply &
openvpn_pid=$!

wait $bastion_pid
wait $openvpn_pid
