#!/bin/sh

echo "Destroying stack..."
sh scripts/destroy_stack.sh
echo "done."

echo "Destroying network..."
sh scripts/destroy_network.sh
echo "done."

echo "Destroying keys..."
sh scripts/destroy_keys.sh
echo "done."
