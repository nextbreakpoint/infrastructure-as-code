#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/ecs && tf_destroy
