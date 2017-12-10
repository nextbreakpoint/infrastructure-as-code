#!/bin/sh

. $ROOT/bash_aliases

export DIR=$ROOT

cd $DIR/terraform/keys && tf_init && tf_plan && tf_apply

cd $DIR/terraform/keys && terraform output -json
