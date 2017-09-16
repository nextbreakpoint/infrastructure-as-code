#!/bin/bash
bash -c "$(find terraform -name "remote_state.tf" -exec echo "sed -i '.bkp' 's/bucket = \".*\"/bucket = \"$1\"/g; s/region = \".*\"/region = \"$2\"/g' {}" \;)"
#find . -name "*.tf.bkp" -exec rm {} \;
