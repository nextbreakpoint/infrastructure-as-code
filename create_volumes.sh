#!/bin/bash
DIR=$(pwd)
source bash_alias

# Create volumes
cd $DIR/terraform/volumes && tf_init && tf_plan && tf_apply

# Initialize volumes
cd $DIR/terraform/maintenance && tf_init && tf_plan && tf_apply && tf_destroy
