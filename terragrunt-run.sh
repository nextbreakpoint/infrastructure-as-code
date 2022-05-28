#!/bin/sh

set -e

POSITIONAL_ARGS=()

PROFILE=""
REGION=""
BUCKET=""
MODULE=""
COMMAND="apply"
OPTIONS=""

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
    --module=*)
      MODULE="${i#*=}"
      shift
      ;;
    --command=*)
      COMMAND="${i#*=}"
      shift
      ;;
    --options=*)
      OPTIONS="${i#*=}"
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

if [[ -z $MODULE ]]; then
  echo "Missing required parameter --module"
  exit 1
fi

if [[ -z $COMMAND ]]; then
  echo "Missing required parameter --command"
  exit 1
fi

pushd terraform/${MODULE} > /dev/null

export AWS_PROFILE=${PROFILE}
export AWS_REGION=${REGION}
export BUCKET_NAME=${BUCKET}

terragrunt ${COMMAND} ${OPTIONS} #--terragrunt-log-level debug --terragrunt-debug

popd > /dev/null
