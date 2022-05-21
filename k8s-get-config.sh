#!/bin/sh

set -e

PROFILE=""
ACCOUNT=""
REGION=""
ROLE=""
CLUSTER=""

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
    --role=*)
      ROLE="${i#*=}"
      shift
      ;;
    --cluster=*)
      CLUSTER="${i#*=}"
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

if [[ -z $ROLE ]]; then
  echo "Missing required parameter --role"
  exit 1
fi

if [[ -z $CLUSTER ]]; then
  echo "Missing required parameter --cluster"
  exit 1
fi

export $(./assume-role.sh --profile=${PROFILE} --account=${ACCOUNT} --role=Terraform-Manage-Clusters)

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

aws eks update-kubeconfig --region ${REGION} --name ${CLUSTER} --role-arn arn:aws:iam::${ACCOUNT}:role/${ROLE}
