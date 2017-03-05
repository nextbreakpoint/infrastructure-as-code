##############################################################################
# Provider
##############################################################################

provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
  shared_credentials_file = "${var.aws_shared_credentials_file}"
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
