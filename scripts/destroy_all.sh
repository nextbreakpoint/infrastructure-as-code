#!/bin/sh

echo "Destroying Pipeline..."
sh scripts/destroy_pipeline.sh
echo "done."

echo "Destroying ELK..."
sh scripts/destroy_elk.sh
echo "done."

echo "Destroying stack..."
sh scripts/destroy_stack.sh
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
