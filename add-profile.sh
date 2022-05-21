#!/bin/sh

set -e

ACCESS_KEY_ID=""
SECRET_ACCESS_KEY=""
REGION=""
PROFILE=""

for i in "$@"; do
  case $i in
    --access-key-id=*)
      ACCESS_KEY_ID="${i#*=}"
      shift
      ;;
    --secret-access-key=*)
      SECRET_ACCESS_KEY="${i#*=}"
      shift
      ;;
    --region=*)
      REGION="${i#*=}"
      shift
      ;;
    --profile=*)
      PROFILE="${i#*=}"
      shift
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ -z $ACCESS_KEY_ID ]]; then
  echo "Missing required parameter --access-key-id"
  exit 1
fi

if [[ -z $SECRET_ACCESS_KEY ]]; then
  echo "Missing required parameter --secret-access-key"
  exit 1
fi

if [[ -z $REGION ]]; then
  echo "Missing required parameter --region"
  exit 1
fi

if [[ -z $PROFILE ]]; then
  echo "Missing required parameter --profile"
  exit 1
fi

aws configure set profile.${PROFILE}.aws_access_key_id ${ACCESS_KEY_ID}
aws configure set profile.${PROFILE}.aws_secret_access_key ${SECRET_ACCESS_KEY}
aws configure set profile.${PROFILE}.region ${REGION}
aws configure set profile.${PROFILE}.output json
