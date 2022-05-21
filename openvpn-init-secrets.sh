#!/bin/sh

set -e

POSITIONAL_ARGS=()

PROFILE=""
ACCOUNT=""
REGION=""
BUCKET=""

for i in "$@"; do
  case $i in
    --profile=*)
      PROFILE="${i#*=}"
      shift
      ;;
    --account=*)
      ACCOUNT="${i#*=}"
      shift
      ;;
    --region=*)
      REGION="${i#*=}"
      shift
      ;;
    --bucket=*)
      BUCKET="${i#*=}"
      shift
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ -z $PROFILE ]]; then
  echo "Missing required parameter --profile"
  exit 1
fi

if [[ -z $ACCOUNT ]]; then
  echo "Missing required parameter --account"
  exit 1
fi

if [[ -z $REGION ]]; then
  echo "Missing required parameter --region"
  exit 1
fi

if [[ -z $BUCKET ]]; then
  echo "Missing required parameter --bucket"
  exit 1
fi

export $(./assume-role.sh --profile=${PROFILE} --account=${ACCOUNT} --role=Terraform-Manage-Bootstrap)

if [[ -z $AWS_ACCESS_KEY_ID ]]; then
  echo "Missing required access key id"
  exit 1
fi

if [[ -z $AWS_SECRET_ACCESS_KEY ]]; then
  echo "Missing required secret access key"
  exit 1
fi

if [[ -z $AWS_SESSION_TOKEN ]]; then
  echo "Missing required session token"
  exit 1
fi

aws --region ${REGION} s3 mb s3://${BUCKET}
