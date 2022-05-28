#!/bin/sh

set -e

POSITIONAL_ARGS=()

PROFILE=""
REGION=""
BUCKET=""
KEY=""

for i in "$@"; do
  case $i in
    --profile=*)
      PROFILE="${i#*=}"
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
    --key=*)
      KEY="${i#*=}"
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

if [[ -z $REGION ]]; then
  echo "Missing required parameter --region"
  exit 1
fi

if [[ -z $BUCKET ]]; then
  echo "Missing required parameter --bucket"
  exit 1
fi

if [[ -z $KEY ]]; then
  echo "Missing required parameter --key"
  exit 1
fi

pushd terraform/subnets > /dev/null

export AWS_PROFILE=${PROFILE}
export AWS_REGION=${REGION}
export BUCKET_NAME=${BUCKET}

terragrunt output | jq -r ".[\"${KEY}\"].value"

popd > /dev/null
