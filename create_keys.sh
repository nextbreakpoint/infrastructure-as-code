#!/bin/bash
DIR=$(pwd)
source alias.sh

cd $DIR/terraform/keys && tf_init && tf_apply
