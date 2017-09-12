#!/bin/bash
DIR=$(pwd)
source alias.sh

cd $DIR/terraform/volumes && tf_init && tf_apply
