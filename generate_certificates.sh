#!/bin/bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ecs-cluster-elb.key -out ecs-cluster-elb.crt

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout web-server-elb.key -out web-server-elb.crt
