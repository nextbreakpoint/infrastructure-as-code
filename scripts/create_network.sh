#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/network && tf_init

cd $ROOT/terraform/network && tf_plan

read -p "Do you want to apply this plan? " confirm

if [ "$confirm" = "yes" ]; then
  cd $ROOT/terraform/network && tf_apply
fi
