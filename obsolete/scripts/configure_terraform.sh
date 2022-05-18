#!/bin/sh

echo "Configuring backend with bucket $1..."

AWS_REGION=$(cat $ROOT/config/misc.json | jq -r ".aws_region")

bash -c "$(find terraform -name "remote_state.tf" -exec echo "sed -i.backup 's/bucket = \".*\"/bucket = \"$1\"/g; s/region = \".*\"/region = \"${AWS_REGION}\"/g' {}" \;)"

echo "done."
