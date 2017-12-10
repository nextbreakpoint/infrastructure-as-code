#!/bin/sh

. $ROOT/bash_aliases

export DIR=$ROOT

cd $DIR/terraform/openvpn && tf_destroy &
openvpn_pid=$!

cd $DIR/terraform/bastion && tf_destroy &
bastion_pid=$!

wait $openvpn_pid
wait $bastion_pid

cd $DIR/terraform/network && tf_destroy

cd $DIR/terraform/vpc && tf_destroy
