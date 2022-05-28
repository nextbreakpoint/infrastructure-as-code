#!/bin/sh

set -e

POSITIONAL_ARGS=()

PROFILE=""
ACCOUNT=""
MESSAGE=""

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
    --message=*)
      MESSAGE="${i#*=}"
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

if [[ -z $MESSAGE ]]; then
  echo "Missing required parameter --message"
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

aws sts decode-authorization-message --encoded-message $MESSAGE | jq -r '.DecodedMessage' | jq
