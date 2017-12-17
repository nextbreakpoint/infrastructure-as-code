#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/network && tf_init
cd $ROOT/terraform/bastion && tf_init
cd $ROOT/terraform/openvpn && tf_init

cd $ROOT/terraform/network && tf_plan
cd $ROOT/terraform/bastion && tf_plan
cd $ROOT/terraform/openvpn && tf_plan

cd $ROOT/terraform/network && tf_apply
cd $ROOT/terraform/bastion && tf_apply
cd $ROOT/terraform/openvpn && tf_apply
