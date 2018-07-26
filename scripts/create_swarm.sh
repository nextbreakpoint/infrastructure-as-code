#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/swarm && tf_init

cd $ROOT/terraform/swarm && tf_plan

read -p "Do you want to apply this plan? " confirm

if [ "$confirm" = "yes" ]; then
  cd $ROOT/terraform/swarm && tf_apply
fi
