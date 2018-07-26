#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/openvpn && tf_init

cd $ROOT/terraform/openvpn && tf_plan

read -p "Do you want to apply this plan? " confirm

if [ "$confirm" = "yes" ]; then
  cd $ROOT/terraform/openvpn && tf_apply
fi
