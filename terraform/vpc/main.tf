##############################################################################
# Provider
##############################################################################

provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
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

resource "aws_vpc" "openvpn" {
  cidr_block = "${var.aws_openvpn_vpc_cidr}"
  instance_tenancy = "default"
  enable_dns_support = "true"
  enable_dns_hostnames = "true"

  tags {
    Name = "openvpn-vpc"
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

resource "aws_internet_gateway" "openvpn" {
  vpc_id = "${aws_vpc.openvpn.id}"

  tags {
      Name = "openvpn-internet-gateway"
      Stream = "${var.stream_tag}"
  }
}

resource "aws_vpc_dhcp_options" "network" {
  domain_name = "${var.aws_region}.compute.internal"
  domain_name_servers  = ["127.0.0.1", "AmazonProvidedDNS"]
  ntp_servers = ["127.0.0.1"]
  netbios_name_servers = ["127.0.0.1"]
  netbios_node_type = 2

  tags {
    Name = "network-internal"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_vpc_dhcp_options" "bastion" {
  domain_name = "${var.aws_region}.compute.internal"
  domain_name_servers = ["AmazonProvidedDNS"]
  ntp_servers = ["127.0.0.1"]

  tags {
    Name = "bastion-internal"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_vpc_dhcp_options" "openvpn" {
  domain_name = "${var.aws_region}.compute.internal"
  domain_name_servers = ["AmazonProvidedDNS", "8.8.4.4", "8.8.8.8"]
  ntp_servers = ["127.0.0.1"]

  tags {
    Name = "openvpn-internal"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_vpc_dhcp_options_association" "dns_network" {
  vpc_id = "${aws_vpc.network.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.network.id}"
}

resource "aws_vpc_dhcp_options_association" "dns_bastion" {
  vpc_id = "${aws_vpc.bastion.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.bastion.id}"
}

resource "aws_vpc_dhcp_options_association" "dns_openvpn" {
  vpc_id = "${aws_vpc.openvpn.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.openvpn.id}"
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

resource "aws_vpc_peering_connection" "network_to_openvpn" {
  peer_vpc_id = "${aws_vpc.openvpn.id}"
  vpc_id = "${aws_vpc.network.id}"
  auto_accept = true

  tags {
    Name = "network-to-openvpn-peering"
    Stream = "${var.stream_tag}"
  }
}

##############################################################################
# Route 53
##############################################################################

resource "aws_route53_zone" "network" {
  name = "${var.network_hosted_zone_name}"
  vpc_id = "${aws_vpc.network.id}"

  tags {
    Name = "network-private-zone"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_route53_zone" "bastion" {
  name = "${var.bastion_hosted_zone_name}"
  vpc_id = "${aws_vpc.bastion.id}"

  tags {
    Name = "bastion-private-zone"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_route53_zone" "openvpn" {
  name = "${var.openvpn_hosted_zone_name}"
  vpc_id = "${aws_vpc.openvpn.id}"

  tags {
    Name = "openvpn-private-zone"
    Stream = "${var.stream_tag}"
  }
}
