#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/lb && tf_init
cd $ROOT/terraform/lb && tf_plan
cd $ROOT/terraform/lb && tf_apply
