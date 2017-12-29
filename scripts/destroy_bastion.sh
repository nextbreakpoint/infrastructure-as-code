#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/bastion && tf_destroy
