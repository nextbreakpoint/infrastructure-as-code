#!/bin/bash
sh create_keys.sh
sh create_network.sh
sh build_images.sh
sh configure_consul.sh
sh create_stack.sh
