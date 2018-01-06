#!/bin/sh

. $ROOT/bash_aliases

cd $ROOT/terraform/kibana && tf_destroy
cd $ROOT/terraform/logstash && tf_destroy
cd $ROOT/terraform/elasticsearch && tf_destroy
