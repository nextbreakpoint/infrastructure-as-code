#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/keys && tf_init

cd $ROOT/terraform/keys && tf_plan

read -p "Do you want to apply this plan? " confirm

if [ "$confirm" = "yes" ]; then
  cd $ROOT/terraform/keys && tf_apply
fi

cd $ROOT/terraform/keys && terraform output -json
