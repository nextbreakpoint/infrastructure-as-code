##############################################################################
# Providers
##############################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region  = "${var.aws_region}"
}

##############################################################################
# Resources
##############################################################################

resource "aws_vpc" "platform" {
  cidr_block           = "${var.aws_platform_vpc_cidr}"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-platform"
  }
}

resource "aws_vpc" "bastion" {
  cidr_block           = "${var.aws_bastion_vpc_cidr}"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-bastion"
  }
}

resource "aws_vpc" "openvpn" {
  cidr_block           = "${var.aws_openvpn_vpc_cidr}"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-openvpn"
  }
}

resource "aws_internet_gateway" "platform" {
  vpc_id = "${aws_vpc.platform.id}"

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-platform"
  }
}

resource "aws_internet_gateway" "bastion" {
  vpc_id = "${aws_vpc.bastion.id}"

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-bastion"
  }
}

resource "aws_internet_gateway" "openvpn" {
  vpc_id = "${aws_vpc.openvpn.id}"

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-openvpn"
  }
}

resource "aws_vpc_dhcp_options" "platform" {
  domain_name_servers = ["AmazonProvidedDNS"]

  ntp_servers = ["127.0.0.1"]

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-platform"
  }
}

resource "aws_vpc_dhcp_options" "bastion" {
  domain_name_servers = ["AmazonProvidedDNS"]

  ntp_servers = ["127.0.0.1"]

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-bastion"
  }
}

resource "aws_vpc_dhcp_options" "openvpn" {
  domain_name_servers = ["AmazonProvidedDNS"]

  ntp_servers = ["127.0.0.1"]

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-openvpn"
  }
}

resource "aws_vpc_dhcp_options_association" "platform" {
  vpc_id          = "${aws_vpc.platform.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.platform.id}"
}

resource "aws_vpc_dhcp_options_association" "bastion" {
  vpc_id          = "${aws_vpc.bastion.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.bastion.id}"
}

resource "aws_vpc_dhcp_options_association" "openvpn" {
  vpc_id          = "${aws_vpc.openvpn.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.openvpn.id}"
}

resource "aws_vpc_peering_connection" "bastion_to_platform" {
  peer_vpc_id = "${aws_vpc.bastion.id}"
  vpc_id      = "${aws_vpc.platform.id}"
  auto_accept = true

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-bastion-to-platform"
  }
}

resource "aws_vpc_peering_connection" "openvpn_to_platform" {
  peer_vpc_id = "${aws_vpc.openvpn.id}"
  vpc_id      = "${aws_vpc.platform.id}"
  auto_accept = true

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-openvpn-to-platform"
  }
}

resource "aws_vpc_peering_connection" "bastion_to_openvpn" {
  peer_vpc_id = "${aws_vpc.openvpn.id}"
  vpc_id      = "${aws_vpc.bastion.id}"
  auto_accept = true

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-bastion-to-openvpn"
  }
}
