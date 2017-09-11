#!/usr/bin/env bash
set -e

echo "Fetching Kubernetes..."
sudo curl -LO https://storage.googleapis.com/kubernetes-release/release/v${KUBERNETES_VERSION}/bin/linux/amd64/kubectl

echo "Installing Kubernetes..."
sudo chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

kubectl cluster-info

echo "Kubernetes installed."
