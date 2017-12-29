#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/bastion && tf_init
cd $ROOT/terraform/bastion && tf_plan
cd $ROOT/terraform/bastion && tf_apply
