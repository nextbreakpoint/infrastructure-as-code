#!/usr/bin/env bash
set -e

echo "Add Puppet source..."
wget https://apt.puppetlabs.com/puppetlabs-release-pc1-xenial.deb
sudo dpkg -i puppetlabs-release-pc1-xenial.deb
sudo apt update

echo "Puppet source added."
