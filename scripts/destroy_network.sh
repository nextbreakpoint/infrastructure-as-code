#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/openvpn && tf_destroy &
openvpn_pid=$!

cd $ROOT/terraform/bastion && tf_destroy &
bastion_pid=$!

wait $openvpn_pid
wait $bastion_pid

cd $ROOT/terraform/network && tf_destroy
