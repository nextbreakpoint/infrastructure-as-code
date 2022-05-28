#!/bin/sh

set -e

POSITIONAL_ARGS=()

REGION=""
TERRAFORM_BUCKET_NAME=""
ZONE_ID=""
ZONE_NAME=""
KEYS_PATH=""
ENVIRONMENT=""
COLOUR=""
SERVER_IMAGE_VERSION="1.0"
OPENVPN_BUCKET=""
OPENVPN_IMAGE_VERSION="1.0"
OPENVPN_KEY_PASSWORD="changeit"
OPENVPN_KEYSTORE_PASSWORD="changeit"
OPENVPN_TRUSTSTORE_PASSWORD="changeit"
OPENVPN_ENABLED="false"
BASTION_ENABLED="false"
PLATFORM_VPC_CIDR="172.32.0.0/16"
BASTION_VPC_CIDR="172.33.0.0/16"
OPENVPN_VPC_CIDR="172.34.0.0/16"
PLATFORM_PUBLIC_SUBNET_CIDR_A="172.32.0.0/24"
PLATFORM_PUBLIC_SUBNET_CIDR_B="172.32.2.0/24"
PLATFORM_PUBLIC_SUBNET_CIDR_C="172.32.4.0/24"
PLATFORM_PRIVATE_SUBNET_CIDR_A="172.32.1.0/24"
PLATFORM_PRIVATE_SUBNET_CIDR_B="172.32.3.0/24"
PLATFORM_PRIVATE_SUBNET_CIDR_C="172.32.5.0/24"
BASTION_SUBNET_CIDR_A="172.33.0.0/24"
BASTION_SUBNET_CIDR_B="172.33.2.0/24"
OPENVPN_SUBNET_CIDR_A="172.34.0.0/24"
OPENVPN_SUBNET_CIDR_B="172.34.2.0/24"

for i in "$@"; do
  case $i in
    --region=*)
      REGION="${i#*=}"
      shift
      ;;
    --hosted-zone-id=*)
      ZONE_ID="${i#*=}"
      shift
      ;;
    --hosted-zone-name=*)
      ZONE_NAME="${i#*=}"
      shift
      ;;
    --keys-path=*)
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
    --terraform-bucket-name=*)
      TERRAFORM_BUCKET_NAME="${i#*=}"
      shift
      ;;
    --openvpn-bucket-name=*)
      OPENVPN_BUCKET_NAME="${i#*=}"
      shift
      ;;
    --server-image-version=*)
      SERVER_IMAGE_VERSION="${i#*=}"
      shift
      ;;
    --openvpn-image-version=*)
      OPENVPN_IMAGE_VERSION="${i#*=}"
      shift
      ;;
    --openvpn-key-password=*)
      OPENVPN_KEY_PASSWORD="${i#*=}"
      shift
      ;;
    --openvpn-keystore-password=*)
      OPENVPN_KEYSTORE_PASSWORD="${i#*=}"
      shift
      ;;
    --openvpn-truststore-password=*)
      OPENVPN_TRUSTSTORE_PASSWORD="${i#*=}"
      shift
      ;;
    --openvpn-enabled=*)
      OPENVPN_ENABLED="${i#*=}"
      shift
      ;;
    --bastion-enabled=*)
      BASTION_ENABLED="${i#*=}"
      shift
      ;;
    --platform-vpc-cidr=*)
      PLATFORM_VPC_CIDR="${i#*=}"
      shift
      ;;
    --bastion-vpc-cidr=*)
      BASTION_VPC_CIDR="${i#*=}"
      shift
      ;;
    --openvpn-vpc-cidr=*)
      OPENVPN_VPC_CIDR="${i#*=}"
      shift
      ;;
    --platform-public-subnet-cidr-a=*)
      PLATFORM_PUBLIC_SUBNET_CIDR_A="${i#*=}"
      shift
      ;;
    --platform-public-subnet-cidr-b=*)
      PLATFORM_PUBLIC_SUBNET_CIDR_B="${i#*=}"
      shift
      ;;
    --platform-public-subnet-cidr-b=*)
      PLATFORM_PUBLIC_SUBNET_CIDR_C="${i#*=}"
      shift
      ;;
    --platform-private-subnet-cidr-a=*)
      PLATFORM_PRIVATE_SUBNET_CIDR_A="${i#*=}"
      shift
      ;;
    --platform-private-subnet-cidr-b=*)
      PLATFORM_PRIVATE_SUBNET_CIDR_B="${i#*=}"
      shift
      ;;
    --platform-private-subnet-cidr-b=*)
      PLATFORM_PRIVATE_SUBNET_CIDR_C="${i#*=}"
      shift
      ;;
    --bastion-public-subnet-cidr-a=*)
      BASTION_SUBNET_CIDR_A="${i#*=}"
      shift
      ;;
    --bastion-public-subnet-cidr-b=*)
      BASTION_SUBNET_CIDR_B="${i#*=}"
      shift
      ;;
    --openvpn-public-subnet-cidr-a=*)
      OPENVPN_SUBNET_CIDR_A="${i#*=}"
      shift
      ;;
    --openvpn-public-subnet-cidr-b=*)
      OPENVPN_SUBNET_CIDR_B="${i#*=}"
      shift
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ -z $REGION ]]; then
  echo "Missing required parameter --region"
  exit 1
fi

if [[ -z $ZONE_ID ]]; then
  echo "Missing required parameter --hosted-zone-id"
  exit 1
fi

if [[ -z $ZONE_NAME ]]; then
  echo "Missing required parameter --hosted-zone-name"
  exit 1
fi

if [[ -z $KEYS_PATH ]]; then
  echo "Missing required parameter --keys-path"
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

if [[ -z $TERRAFORM_BUCKET_NAME ]]; then
  echo "Missing required parameter --terraform-bucket-name"
  exit 1
fi

if [[ -z $OPENVPN_BUCKET_NAME ]]; then
  echo "Missing required parameter --openvpn-bucket-name"
  exit 1
fi

cat <<END >terraform/terragrunt.hcl
remote_state {
  backend = "s3"
  disable_init = false
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket = "${TERRAFORM_BUCKET_NAME}"
    dynamodb_table = "${TERRAFORM_BUCKET_NAME}"
    key = "\${path_relative_to_include()}/terraform.tfstate"
    region = "${REGION}"
    encrypt = true
    skip_bucket_root_access = true
  }
}

inputs = {
  aws_region = "${REGION}"
  aws_platform_vpc_cidr = "172.32.0.0/16"
  aws_bastion_vpc_cidr = "172.33.0.0/16"
  aws_openvpn_vpc_cidr = "172.34.0.0/16"
  aws_platform_public_subnet_cidr_a = "172.32.0.0/24"
  aws_platform_public_subnet_cidr_b = "172.32.2.0/24"
  aws_platform_public_subnet_cidr_c = "172.32.4.0/24"
  aws_platform_private_subnet_cidr_a = "172.32.1.0/24"
  aws_platform_private_subnet_cidr_b = "172.32.3.0/24"
  aws_platform_private_subnet_cidr_c = "172.32.5.0/24"
  aws_bastion_subnet_cidr_a = "172.33.0.0/24"
  aws_bastion_subnet_cidr_b = "172.33.2.0/24"
  aws_openvpn_subnet_cidr_a = "172.34.0.0/24"
  aws_openvpn_subnet_cidr_b = "172.34.2.0/24"
  hosted_zone_id = "${ZONE_ID}"
  hosted_zone_name = "${ZONE_NAME}"
  keys_path = "${KEYS_PATH}"
  environment = "${ENVIRONMENT}"
  colour = "${COLOUR}"
  terraform_bucket_name = "${TERRAFORM_BUCKET_NAME}"
  server_image_version = "${SERVER_IMAGE_VERSION}"
  openvpn_image_version = "${OPENVPN_IMAGE_VERSION}"
  openvpn_bucket_name = "${OPENVPN_BUCKET_NAME}"
  openvpn_key_password = "${OPENVPN_KEY_PASSWORD}"
  openvpn_keystore_password = "${OPENVPN_KEYSTORE_PASSWORD}"
  openvpn_truststore_password = "${OPENVPN_TRUSTSTORE_PASSWORD}"
  openvpn = ${OPENVPN_ENABLED}
  bastion = ${BASTION_ENABLED}
}

generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.2"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "local" {}
EOF
}

generate "common" {
  path = "common.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
### MANDATORY ###
variable "aws_region" {}

### MANDATORY ###
variable "environment" {}

### MANDATORY ###
variable "colour" {}

### MANDATORY ###
variable "terraform_bucket_name" {}
EOF
}
END
