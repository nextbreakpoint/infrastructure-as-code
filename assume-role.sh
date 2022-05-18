#!/bin/sh

set -e

POSITIONAL_ARGS=()

PROFILE="terraform"
ACCOUNT_ID=""
ROLE_NAME=""

for i in "$@"; do
  case $i in
    --profile=*)
      PROFILE="${i#*=}"
      shift
      ;;
    --account=*)
      ACCOUNT_ID="${i#*=}"
      shift
      ;;
    --role=*)
      ROLE_NAME="${i#*=}"
      shift
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ -z $ROLE_NAME ]]; then
  echo "Missing required parameter --role"
  exit 1
fi

if [[ -z $ACCOUNT_ID ]]; then
  echo "Missing required parameter --account"
  exit 1
fi

$(aws --profile ${PROFILE} sts assume-role --role-arn arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME} --role-session-name Terraform --duration-seconds=3600 | jq --raw-output '"export AWS_ACCESS_KEY_ID=" + .Credentials.AccessKeyId + "\nexport AWS_SECRET_ACCESS_KEY=" + .Credentials.SecretAccessKey + "\nexport AWS_SESSION_TOKEN=" + .Credentials.SessionToken')

echo "export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID"
echo "export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY"
echo "export AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN"
