#!/bin/sh

set +e

POSITIONAL_ARGS=()

ACCOUNT=""

for i in "$@"; do
  case $i in
    --account=*)
      ACCOUNT="${i#*=}"
      shift
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ -z $ACCOUNT ]]; then
  echo "Missing required parameter --account"
  exit 1
fi

mkdir -p policies

cat <<EOF >policies/assume-role.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${ACCOUNT}:root"
      }
    }
  ]
}
EOF

cat <<EOF >policies/assume-role-manage-boostrap.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Resource": [
        "arn:aws:iam::${ACCOUNT}:role/Terraform-Manage-Bootstrap"
      ]
    }
  ]
}
EOF
