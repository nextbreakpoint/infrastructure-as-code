#!/bin/bash
sh destroy_stack.sh
sh destroy_volumes.sh
sh destroy_network.sh
sh destroy_keys.sh
sh delete_images.sh
