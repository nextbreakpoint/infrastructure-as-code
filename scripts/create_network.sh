#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/network && tf_init
cd $ROOT/terraform/network && tf_plan
cd $ROOT/terraform/network && tf_apply
