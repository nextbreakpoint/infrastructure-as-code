##############################################################################
# Providers
##############################################################################

provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
  version = "~> 0.1"
}

##############################################################################
# Resources
##############################################################################

resource "aws_vpc" "network" {
  cidr_block           = "${var.aws_network_vpc_cidr}"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  tags {
    Name   = "network"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_vpc" "bastion" {
  cidr_block           = "${var.aws_bastion_vpc_cidr}"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  tags {
    Name   = "bastion"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_vpc" "openvpn" {
  cidr_block           = "${var.aws_openvpn_vpc_cidr}"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  tags {
    Name   = "openvpn"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_internet_gateway" "network" {
  vpc_id = "${aws_vpc.network.id}"

  tags {
    Name   = "network"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_internet_gateway" "bastion" {
  vpc_id = "${aws_vpc.bastion.id}"

  tags {
    Name   = "bastion"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_internet_gateway" "openvpn" {
  vpc_id = "${aws_vpc.openvpn.id}"

  tags {
    Name   = "openvpn"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_vpc_dhcp_options" "network" {
  domain_name_servers = ["127.0.0.1", "AmazonProvidedDNS"]

  ntp_servers = ["127.0.0.1"]

  tags {
    Name   = "network"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_vpc_dhcp_options" "bastion" {
  domain_name_servers = ["AmazonProvidedDNS"]

  ntp_servers = ["127.0.0.1"]

  tags {
    Name   = "bastion"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_vpc_dhcp_options" "openvpn" {
  domain_name_servers = ["AmazonProvidedDNS"]

  ntp_servers = ["127.0.0.1"]

  tags {
    Name   = "openvpn"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_vpc_dhcp_options_association" "network" {
  vpc_id          = "${aws_vpc.network.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.network.id}"
}

resource "aws_vpc_dhcp_options_association" "bastion" {
  vpc_id          = "${aws_vpc.bastion.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.bastion.id}"
}

resource "aws_vpc_dhcp_options_association" "openvpn" {
  vpc_id          = "${aws_vpc.openvpn.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.openvpn.id}"
}

resource "aws_vpc_peering_connection" "network_to_bastion" {
  peer_vpc_id = "${aws_vpc.bastion.id}"
  vpc_id      = "${aws_vpc.network.id}"
  auto_accept = true

  tags {
    Name   = "network-to-bastion"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_vpc_peering_connection" "network_to_openvpn" {
  peer_vpc_id = "${aws_vpc.openvpn.id}"
  vpc_id      = "${aws_vpc.network.id}"
  auto_accept = true

  tags {
    Name   = "network-to-openvpn"
    Stream = "${var.stream_tag}"
  }
}
