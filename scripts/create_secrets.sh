#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/secrets && tf_init

if [ $? -ne 0 ]; then
    exit 1
fi

cd $ROOT/terraform/secrets && tf_plan

if [ $? -ne 0 ]; then
    exit 1
fi

read -p "Do you want to apply this plan? " confirm

if [ "$confirm" = "yes" ]; then
  cd $ROOT/terraform/secrets && tf_apply
fi
