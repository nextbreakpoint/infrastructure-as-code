#!/bin/bash
DIR=$(pwd)
source bash_alias

cd $DIR/terraform/keys && tf_destroy
