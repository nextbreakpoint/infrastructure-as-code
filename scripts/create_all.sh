#!/bin/sh

echo "Creating secrets..."
sh scripts/create_secrets.sh
echo "done."

echo "Creating Network..."
sh scripts/create_network.sh
echo "done."

echo "Creating LBs..."
sh scripts/create_lb.sh
echo "done."

echo "Creating Stack..."
sh scripts/create_ecs.sh
echo "done."
