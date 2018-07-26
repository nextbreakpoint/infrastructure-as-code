#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/bastion && tf_init

cd $ROOT/terraform/bastion && tf_plan

read -p "Do you want to apply this plan? " confirm

if [ "$confirm" = "yes" ]; then
  cd $ROOT/terraform/bastion && tf_apply
fi
