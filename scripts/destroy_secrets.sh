#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/secrets && tf_destroy
