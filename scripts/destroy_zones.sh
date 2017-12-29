#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/zones && tf_destroy
