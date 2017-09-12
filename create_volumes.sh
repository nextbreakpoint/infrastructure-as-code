#!/bin/bash
DIR=$(pwd)
source alias.sh

# Create volumes
cd $DIR/terraform/volumes && tf_init && tf_apply

# Initialize volumes
cd $DIR/terraform/maintenance && tf_init && tf_apply && tf_destroy -force
