#!/usr/bin/env bash
set -e

sudo parted -s ${device_name} mklabel gpt
sudo parted -s --align optimal ${device_name} mkpart primary ext4 0% 100%
sudo parted ${device_name} print
sudo mkfs -F -F -t ext4 ${device_name}1
