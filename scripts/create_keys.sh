#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/keys && tf_init

cd $ROOT/terraform/keys && tf_plan

cd $ROOT/terraform/keys && tf_apply

cd $ROOT/terraform/keys && terraform output -json
