#!/bin/sh

set -e

POSITIONAL_ARGS=()

PROFILE=""
ACCOUNT=""
REGION=""
SUBNET=""
SSH_KEY=""
IMAGE=""
VERSION=""

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
    --subnet=*)
      SUBNET="${i#*=}"
      shift
      ;;
    --ssh-key=*)
      SSH_KEY="${i#*=}"
      shift
      ;;
    --image=*)
      IMAGE="${i#*=}"
      shift
      ;;
    --version=*)
      VERSION="${i#*=}"
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

if [[ -z $SUBNET ]]; then
  echo "Missing required parameter --subnet"
  exit 1
fi

if [[ -z $SSH_KEY ]]; then
  echo "Missing required parameter --ssh-key"
  exit 1
fi

if [[ -z $IMAGE ]]; then
  echo "Missing required parameter --image"
  exit 1
fi

if [[ -z $VERSION ]]; then
  echo "Missing required parameter --version"
  exit 1
fi

export $(./assume-role.sh --profile=${PROFILE} --account=${ACCOUNT} --role=Packer-Build-Images)

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

pushd packer/images/${IMAGE}

packer build --var key_path="../../../keys" --var key_name=${SSH_KEY} --var base_version=${VERSION} --var aws_subnet_id=${SUBNET} --var aws_region=${REGION} packer.json

popd > /dev/null
