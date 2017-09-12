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

provider "template" {
  version = "~> 0.1"
}

##############################################################################
# Remote state
##############################################################################

terraform {
  backend "s3" {
    bucket = "nextbreakpoint-terraform-state"
    region = "eu-west-1"
    key = "keys.tfstate"
  }
}

##############################################################################
# Keys
##############################################################################

data "template_file" "public_key" {
  template = "${file("${var.key_path}.pub")}"
}

resource "aws_key_pair" "deployer_key" {
  key_name   = "${var.key_name}"
  public_key = "${data.template_file.public_key.rendered}"
}
