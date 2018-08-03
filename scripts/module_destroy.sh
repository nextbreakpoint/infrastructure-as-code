#!/bin/sh

. $ROOT/bash_aliases

MODULE=$1

if [ -z "$MODULE" ]; then
    exit 1
fi

cd $ROOT/terraform/$MODULE && tf_destroy

if [ $? -ne 0 ]; then
    exit 1
fi
