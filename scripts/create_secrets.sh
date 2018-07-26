#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/secrets && tf_init

cd $ROOT/terraform/secrets && tf_plan

read -p "Do you want to apply this plan? " confirm

if [ "$confirm" = "yes" ]; then
  cd $ROOT/terraform/secrets && tf_apply
fi
