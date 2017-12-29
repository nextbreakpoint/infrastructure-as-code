#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/zones && tf_init
cd $ROOT/terraform/zones && tf_plan
cd $ROOT/terraform/zones && tf_apply
