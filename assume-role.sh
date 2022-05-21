#!/bin/sh

set -e

POSITIONAL_ARGS=()

PROFILE=""
ACCOUNT=""
ROLE=""

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
    --role=*)
      ROLE="${i#*=}"
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

if [[ -z $ROLE ]]; then
  echo "Missing required parameter --role"
  exit 1
fi

$(aws --profile ${PROFILE} sts assume-role --role-arn arn:aws:iam::${ACCOUNT}:role/${ROLE} --role-session-name Terraform --duration-seconds=3600 | jq --raw-output '"export ACCESS_KEY_ID=" + .Credentials.AccessKeyId + "\nexport SECRET_ACCESS_KEY=" + .Credentials.SecretAccessKey + "\nexport SESSION_TOKEN=" + .Credentials.SessionToken')

if [[ -z $ACCESS_KEY_ID ]]; then
  exit 1
fi

if [[ -z $SECRET_ACCESS_KEY ]]; then
  exit 1
fi

if [[ -z $SESSION_TOKEN ]]; then
  exit 1
fi

echo "AWS_ACCESS_KEY_ID=\"${ACCESS_KEY_ID}\"\nAWS_SECRET_ACCESS_KEY=\"${SECRET_ACCESS_KEY}\"\nAWS_SESSION_TOKEN=\"${SESSION_TOKEN}\""
