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
# DNS
##############################################################################

resource "aws_vpc_dhcp_options" "consul" {
  domain_name          = "${var.aws_region}.compute.internal"
  domain_name_servers  = ["127.0.0.1", "AmazonProvidedDNS"]
  ntp_servers          = ["127.0.0.1"]
  netbios_name_servers = ["127.0.0.1"]
  netbios_node_type    = 2

  tags {
    Name = "consul"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = "${data.terraform_remote_state.vpc.network-vpc-id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.consul.id}"
}
