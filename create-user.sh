#!/bin/sh

set -e

PROFILE=""
USER_PROFILE=""
USER_NAME=""
GROUP_NAME=""
REGION=""

for i in "$@"; do
  case $i in
    --profile=*)
      PROFILE="${i#*=}"
      shift
      ;;
    --user-profile=*)
      USER_PROFILE="${i#*=}"
      shift
      ;;
    --user-name=*)
      USER_NAME="${i#*=}"
      shift
      ;;
    --group-name=*)
      GROUP_NAME="${i#*=}"
      shift
      ;;
    --region=*)
      REGION="${i#*=}"
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

if [[ -z $USER_PROFILE ]]; then
  echo "Missing required parameter --user-profile"
  exit 1
fi

if [[ -z $USER_NAME ]]; then
  echo "Missing required parameter --user-name"
  exit 1
fi

if [[ -z $GROUP_NAME ]]; then
  echo "Missing required parameter --group-name"
  exit 1
fi

if [[ -z $REGION ]]; then
  echo "Missing required parameter --region"
  exit 1
fi

aws --profile ${PROFILE} iam create-user --user-name ${USER_NAME}

aws --profile ${PROFILE} iam add-user-to-group --user-name ${USER_NAME} --group-name ${GROUP_NAME}

$(aws --profile ${PROFILE} iam create-access-key --user-name ${USER_NAME} | jq --raw-output '"export ACCESS_KEY_ID=" + .AccessKey.AccessKeyId + "\nexport SECRET_ACCESS_KEY=" + .AccessKey.SecretAccessKey')

if [[ -z $ACCESS_KEY_ID ]]; then
  echo "Missing required access key id"
  exit 1
fi

if [[ -z $SECRET_ACCESS_KEY ]]; then
  echo "Missing required secret access key"
  exit 1
fi

./add-profile.sh --access-key-id=${ACCESS_KEY_ID} --secret-access-key=${SECRET_ACCESS_KEY} --region=${REGION} --profile=${USER_PROFILE}
