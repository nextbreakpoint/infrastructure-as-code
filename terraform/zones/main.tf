##############################################################################
# Provider
##############################################################################

provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
  version = "~> 0.1"
}

##############################################################################
# Route 53
##############################################################################

resource "aws_route53_zone" "network" {
  name = "${var.hosted_zone_name}"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  tags {
    Name = "network-private-zone"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_route53_zone" "bastion" {
  name = "${var.hosted_zone_name}"
  vpc_id = "${data.terraform_remote_state.vpc.bastion-vpc-id}"

  tags {
    Name = "bastion-private-zone"
    Stream = "${var.stream_tag}"
  }
}
