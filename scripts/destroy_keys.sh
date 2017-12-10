#!/bin/sh

. $ROOT/bash_aliases

export DIR=$ROOT

cd $DIR/terraform/keys && tf_destroy
