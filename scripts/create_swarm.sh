#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/swarm && tf_init
cd $ROOT/terraform/swarm && tf_plan
cd $ROOT/terraform/swarm && tf_apply
