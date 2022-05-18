#!/usr/bin/env bash

set -e

echo "Installing Docker..."

sudo apt install -y docker.io && \
  sudo systemctl start docker.service && \
  sudo systemctl enable docker.service && \
  sudo docker version && \
  sudo docker info && \
  sudo usermod -aG docker ubuntu

echo "Docker installed."
