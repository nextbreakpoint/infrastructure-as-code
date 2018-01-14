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
sh scripts/create_stack.sh
echo "done."

echo "Creating ELK..."
sh scripts/create_elk.sh
echo "done."

echo "Creating Pipeline..."
sh scripts/create_pipeline.sh
echo "done."
