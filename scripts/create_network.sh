#!/bin/sh

. $ROOT/bash_aliases

# Create network routing tables and NAT boxes
cd $ROOT/terraform/network && tf_init && tf_plan && tf_apply

# Create bastion server
cd $ROOT/terraform/bastion && tf_init && tf_plan && tf_apply &
bastion_pid=$!

# Create openvpn server
cd $ROOT/terraform/openvpn && tf_init && tf_plan && tf_apply &
openvpn_pid=$!

wait $bastion_pid
wait $openvpn_pid
