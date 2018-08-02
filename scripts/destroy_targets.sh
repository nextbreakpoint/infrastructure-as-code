#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/targets && tf_destroy
