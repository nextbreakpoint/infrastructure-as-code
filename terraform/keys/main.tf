##############################################################################
# Providers
##############################################################################

provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
  version = "~> 0.1"
}

provider "template" {
  version = "~> 0.1"
}

##############################################################################
# Resources
##############################################################################

data "template_file" "public_key" {
  template = "${file("${var.key_path}/${var.environment}-${var.colour}-${var.key_name}.pem.pub")}"
}

resource "aws_key_pair" "deployer_key" {
  key_name   = "${var.environment}-${var.colour}-${var.key_name}"
  public_key = "${data.template_file.public_key.rendered}"
}
