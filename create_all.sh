#!/bin/bash
sh create_keys.sh
sh create_network.sh
sh create_volumes.sh
sh build_images.sh
sh create_stack.sh
