#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/openvpn && tf_destroy

cd $ROOT/terraform/bastion && tf_destroy

cd $ROOT/terraform/network && tf_destroy
