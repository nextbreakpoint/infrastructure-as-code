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
# Cloud Watch
##############################################################################

resource "aws_cloudwatch_log_group" "network" {
  name = "network"

  tags {
    environment = "terraform"
  }
}

resource "aws_cloudwatch_log_stream" "network" {
  name = "network"
  log_group_name = "${aws_cloudwatch_log_group.network.name}"
}
