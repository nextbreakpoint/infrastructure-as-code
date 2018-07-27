#!/bin/sh

echo "Creating bucket $1..."

AWS_REGION=$(cat $ROOT/config/misc.json | jq -r ".aws_region")

aws s3api create-bucket --bucket $1 --region $AWS_REGION --create-bucket-configuration LocationConstraint=$AWS_REGION

if [ $? -ne 0 ]; then
    exit 1
fi

echo "done."
