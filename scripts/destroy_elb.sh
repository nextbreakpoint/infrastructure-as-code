#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/elb && tf_destroy
