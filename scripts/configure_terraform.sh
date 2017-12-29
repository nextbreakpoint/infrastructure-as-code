#!/bin/sh

echo "Configuring Terraform..."

echo "Bucket = "$1
echo "Region = "$2

bash -c "$(find terraform -name "remote_state.tf" -exec echo "sed -i.backup 's/bucket = \".*\"/bucket = \"$1\"/g; s/region = \".*\"/region = \"$2\"/g' {}" \;)"

echo "done."
