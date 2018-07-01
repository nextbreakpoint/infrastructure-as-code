#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/ecs && tf_init
cd $ROOT/terraform/ecs && tf_plan
cd $ROOT/terraform/ecs && tf_apply
