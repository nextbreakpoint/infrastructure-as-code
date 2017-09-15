#!/bin/bash
bash -c "$(find terraform -name "remote_state.tf" -exec echo "sed -i '.bkp' 's/bucket = \".*\"/bucket = \"nextbreakpoint-terraform-state\"/g' {}" \;)"
#find . -name "*.tf.bkp" -exec rm {} \;
