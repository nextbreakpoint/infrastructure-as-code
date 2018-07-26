#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/vpc && tf_init

cd $ROOT/terraform/vpc && tf_plan

read -p "Do you want to apply this plan? " confirm

if [ "$confirm" = "yes" ]; then
  cd $ROOT/terraform/vpc && tf_apply
fi
