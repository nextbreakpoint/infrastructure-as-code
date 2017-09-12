#!/bin/bash
DIR=$(pwd)
source bash_alias

cd $DIR/terraform/maintenance && tf_destroy -force

cd $DIR/terraform/volumes && tf_destroy -force
