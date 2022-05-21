#!/bin/sh

set +e

KEYS_PATH=""
ENVIRONMENT=""
COLOUR=""

for i in "$@"; do
  case $i in
    --path=*)
      KEYS_PATH="${i#*=}"
      shift
      ;;
    --environment=*)
      ENVIRONMENT="${i#*=}"
      shift
      ;;
    --colour=*)
      COLOUR="${i#*=}"
      shift
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ -z $KEYS_PATH ]]; then
  echo "Missing required parameter --path"
  exit 1
fi

if [[ -z $ENVIRONMENT ]]; then
  echo "Missing required parameter --environment"
  exit 1
fi

if [[ -z $COLOUR ]]; then
  echo "Missing required parameter --colour"
  exit 1
fi

mkdir -p ${KEYS_PATH}

ssh-keygen -b 2048 -t ed25519 -N "" -f ${KEYS_PATH}/${ENVIRONMENT}-${COLOUR}-openvpn.pem
ssh-keygen -b 2048 -t ed25519 -N "" -f ${KEYS_PATH}/${ENVIRONMENT}-${COLOUR}-bastion.pem
ssh-keygen -b 2048 -t ed25519 -N "" -f ${KEYS_PATH}/${ENVIRONMENT}-${COLOUR}-server.pem
ssh-keygen -b 2048 -t ed25519 -N "" -f ${KEYS_PATH}/${ENVIRONMENT}-${COLOUR}-packer.pem
