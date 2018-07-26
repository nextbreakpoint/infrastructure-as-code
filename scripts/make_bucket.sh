#!/bin/sh

echo "Creating bucket..."

echo "Bucket = "$1
echo "Region = "$2

aws s3api create-bucket --bucket $1 --region $2 --create-bucket-configuration LocationConstraint=$2

echo "done."
