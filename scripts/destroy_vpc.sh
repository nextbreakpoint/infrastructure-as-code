#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/vpc && tf_destroy
