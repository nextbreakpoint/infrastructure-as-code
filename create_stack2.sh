#!/bin/bash
DIR=$(pwd)
source bash_alias

cd $DIR/terraform/secrets && tf_init && tf_plan && tf_apply

cd $DIR/terraform/consul && tf_init && tf_plan && tf_apply

cd $DIR/terraform/webserver && tf_init && tf_plan && tf_apply

cd $DIR/terraform/ecs && tf_init && tf_plan && tf_apply
