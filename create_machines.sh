#!/bin/bash
docker-machine create --driver generic --generic-ip-address=172.32.1.150 --generic-engine-port=2376 --generic-ssh-user ec2-user --generic-ssh-port=2200 --generic-ssh-key deployer_key.pem docker-master-a
docker-machine create --driver generic --generic-ip-address=172.32.1.151 --generic-engine-port=2376 --generic-ssh-user ec2-user --generic-ssh-port=2200 --generic-ssh-key deployer_key.pem docker-worker1-a
docker-machine create --driver generic --generic-ip-address=172.32.1.152 --generic-engine-port=2376 --generic-ssh-user ec2-user --generic-ssh-port=2200 --generic-ssh-key deployer_key.pem docker-worker2-a
docker-machine create --driver generic --generic-ip-address=172.32.3.150 --generic-engine-port=2376 --generic-ssh-user ec2-user --generic-ssh-port=2200 --generic-ssh-key deployer_key.pem docker-master-b
docker-machine create --driver generic --generic-ip-address=172.32.3.151 --generic-engine-port=2376 --generic-ssh-user ec2-user --generic-ssh-port=2200 --generic-ssh-key deployer_key.pem docker-worker1-b
docker-machine create --driver generic --generic-ip-address=172.32.3.152 --generic-engine-port=2376 --generic-ssh-user ec2-user --generic-ssh-port=2200 --generic-ssh-key deployer_key.pem docker-worker2-b
