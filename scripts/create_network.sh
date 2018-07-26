#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/network && tf_init

if [ $? -ne 0 ]; then
    exit 1
fi

cd $ROOT/terraform/network && tf_plan

if [ $? -ne 0 ]; then
    exit 1
fi

read -p "Do you want to apply this plan? " confirm

if [ "$confirm" = "yes" ]; then
  cd $ROOT/terraform/network && tf_apply
fi
