#!/usr/bin/env bash

set -e

echo "Installing tools..."

sudo apt-get update -y && \
  sudo apt-get install -y software-properties-common

sudo apt-get update -y && \
  sudo apt-get install -y zip 

echo "Tools installed."
