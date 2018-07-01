#!/bin/sh

echo "Destroying stack..."
sh scripts/destroy_ecs.sh
echo "done."

echo "Destroying LBs..."
sh scripts/destroy_lb.sh
echo "done."

echo "Destroying network..."
sh scripts/destroy_network.sh
echo "done."

echo "Destroying secrets..."
sh scripts/destroy_secrets.sh
echo "done."
