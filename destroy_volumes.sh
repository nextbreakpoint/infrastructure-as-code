#!/bin/bash
DIR=$(pwd)
source bash_alias

cd $DIR/terraform/volumes && tf_destroy -force
