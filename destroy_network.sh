#!/bin/bash
DIR=$(pwd)
source bash_alias

cd $DIR/terraform/network && tf_destroy -force &
network_pid=$!

cd $DIR/terraform/bastion && tf_destroy -force &
bastion_pid=$!

wait $network_pid
wait $bastion_pid

cd $DIR/terraform/vpc && tf_destroy -force
