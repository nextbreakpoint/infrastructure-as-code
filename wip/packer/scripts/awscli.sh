#!/usr/bin/env bash

set -e

echo "Installing AWS cli..."

sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
  sudo unzip awscliv2.zip && \
  sudo ./aws/install && \
  sudo rm awscliv2.zip && \
  sudo rm -fR aws

echo "AWS cli installed."
