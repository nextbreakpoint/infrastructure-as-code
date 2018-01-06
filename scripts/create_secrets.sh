#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/secrets && tf_init
cd $ROOT/terraform/secrets && tf_plan
cd $ROOT/terraform/secrets && tf_apply
