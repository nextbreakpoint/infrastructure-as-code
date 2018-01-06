#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/consul && tf_init
cd $ROOT/terraform/ecs && tf_init
cd $ROOT/terraform/webserver && tf_init

cd $ROOT/terraform/consul && tf_plan
cd $ROOT/terraform/ecs && tf_plan
cd $ROOT/terraform/webserver && tf_plan

cd $ROOT/terraform/consul && tf_apply
cd $ROOT/terraform/ecs && tf_apply
cd $ROOT/terraform/webserver && tf_apply
