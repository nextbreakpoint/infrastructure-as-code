#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/keys && tf_init && tf_plan && tf_apply

cd $ROOT/terraform/keys && terraform output -json
