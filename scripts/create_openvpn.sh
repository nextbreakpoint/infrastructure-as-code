#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/openvpn && tf_init
cd $ROOT/terraform/openvpn && tf_plan
cd $ROOT/terraform/openvpn && tf_apply
