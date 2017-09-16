#!/bin/bash
aws s3api create-bucket --bucket $1 --region $2 --create-bucket-configuration LocationConstraint=$2
