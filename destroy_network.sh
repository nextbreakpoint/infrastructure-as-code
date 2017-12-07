#!/bin/bash
DIR=$(pwd)
source bash_alias

cd $DIR/terraform/bastion && tf_destroy

cd $DIR/terraform/network && tf_destroy

cd $DIR/terraform/vpc && tf_destroy
