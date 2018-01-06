#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/webserver && tf_destroy
cd $ROOT/terraform/ecs && tf_destroy
cd $ROOT/terraform/consul && tf_destroy
