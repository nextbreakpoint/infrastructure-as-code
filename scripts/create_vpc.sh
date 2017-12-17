#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/vpc && tf_init

cd $ROOT/terraform/vpc && tf_plan

cd $ROOT/terraform/vpc && tf_apply
