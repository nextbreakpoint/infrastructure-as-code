#!/bin/bash
DIR=$(pwd)
source bash_alias

cd $DIR/terraform/ecs && tf_destroy

cd $DIR/terraform/webserver && tf_destroy

cd $DIR/terraform/consul && tf_destroy

cd $DIR/terraform/secrets && tf_destroy
