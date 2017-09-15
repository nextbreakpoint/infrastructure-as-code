##############################################################################
# Provider
##############################################################################

provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
  version = "~> 0.1"
}

provider "terraform" {
    version = "~> 0.1"
}

##############################################################################
# VPC configuration
##############################################################################

resource "aws_vpc" "network" {
  cidr_block = "${var.aws_network_vpc_cidr}"
  instance_tenancy = "default"
  enable_dns_support = "true"
  enable_dns_hostnames = "true"

  tags {
    Name = "network-vpc"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_vpc" "bastion" {
  cidr_block = "${var.aws_bastion_vpc_cidr}"
  instance_tenancy = "default"
  enable_dns_support = "true"
  enable_dns_hostnames = "true"

  tags {
    Name = "bastion-vpc"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_internet_gateway" "network" {
  vpc_id = "${aws_vpc.network.id}"

  tags {
    Name = "network-internet-gateway"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_internet_gateway" "bastion" {
  vpc_id = "${aws_vpc.bastion.id}"

  tags {
      Name = "bastion-internet-gateway"
      Stream = "${var.stream_tag}"
  }
}

resource "aws_vpc_dhcp_options" "network" {
  domain_name = "${var.aws_region}.compute.internal"
  domain_name_servers = ["AmazonProvidedDNS"]

  tags {
    Name = "network-internal"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_vpc_dhcp_options_association" "dns_network" {
  vpc_id = "${aws_vpc.network.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.network.id}"
}

##############################################################################
# Route 53
##############################################################################

resource "aws_route53_zone" "network" {
  name = "${var.hosted_zone_name}"
  vpc_id = "${aws_vpc.network.id}"

  tags {
    Name = "network-private-zone"
    Stream = "${var.stream_tag}"
  }
}

##############################################################################
# VPC Peering
##############################################################################

resource "aws_vpc_peering_connection" "network_to_bastion" {
  peer_vpc_id = "${aws_vpc.bastion.id}"
  vpc_id = "${aws_vpc.network.id}"
  auto_accept = true

  tags {
    Name = "network-to-bastion-peering"
    Stream = "${var.stream_tag}"
  }
}

##############################################################################
# Subnets
##############################################################################

resource "aws_subnet" "network_public_a" {
  vpc_id = "${aws_vpc.network.id}"
  availability_zone = "${format("%s%s", var.aws_region, "a")}"
  cidr_block = "${var.aws_network_public_subnet_cidr_a}"

  tags {
    Name = "public-subnet-a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_subnet" "network_public_b" {
  vpc_id = "${aws_vpc.network.id}"
  availability_zone = "${format("%s%s", var.aws_region, "b")}"
  cidr_block = "${var.aws_network_public_subnet_cidr_b}"

  tags {
    Name = "public-subnet-b"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_subnet" "network_public_c" {
  vpc_id = "${aws_vpc.network.id}"
  availability_zone = "${format("%s%s", var.aws_region, "c")}"
  cidr_block = "${var.aws_network_public_subnet_cidr_c}"

  tags {
    Name = "public-subnet-c"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_subnet" "network_private_a" {
  vpc_id = "${aws_vpc.network.id}"
  availability_zone = "${format("%s%s", var.aws_region, "a")}"
  cidr_block = "${var.aws_network_private_subnet_cidr_a}"

  tags {
    Name = "private-subnet-a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_subnet" "network_private_b" {
  vpc_id = "${aws_vpc.network.id}"
  availability_zone = "${format("%s%s", var.aws_region, "b")}"
  cidr_block = "${var.aws_network_private_subnet_cidr_b}"

  tags {
    Name = "private-subnet-b"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_subnet" "network_private_c" {
  vpc_id = "${aws_vpc.network.id}"
  availability_zone = "${format("%s%s", var.aws_region, "c")}"
  cidr_block = "${var.aws_network_private_subnet_cidr_c}"

  tags {
    Name = "private-subnet-c"
    Stream = "${var.stream_tag}"
  }
}
