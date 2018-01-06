#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/pipeline && tf_init
cd $ROOT/terraform/pipeline && tf_plan
cd $ROOT/terraform/pipeline && tf_apply
