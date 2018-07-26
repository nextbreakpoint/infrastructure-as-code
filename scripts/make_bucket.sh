#!/bin/sh

echo "Creating bucket..."

echo "Bucket = "$1
echo "Region = "$2

aws s3api create-bucket --bucket $1 --region $2 --create-bucket-configuration LocationConstraint=$2

if [ $? -ne 0 ]; then
    exit 1
fi

echo "done."
