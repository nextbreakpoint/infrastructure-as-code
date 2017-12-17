#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/elb && tf_init
cd $ROOT/terraform/elb && tf_plan
cd $ROOT/terraform/elb && tf_apply
