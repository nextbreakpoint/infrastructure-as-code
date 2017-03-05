##############################################################################
# Provider
##############################################################################

provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
  shared_credentials_file = "${var.aws_shared_credentials_file}"
}

##############################################################################
# Volumes
##############################################################################

resource "aws_ebs_volume" "elasticsearch_volume_a" {
  availability_zone = "${format("%s%s", var.aws_region, "a")}"
  size = "${var.volume_size}"
  encrypted = "${var.volume_encrypted}"
  type = "gp2"

  tags {
    Name = "elasticsearch_volume_a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_ebs_volume" "elasticsearch_volume_b" {
  availability_zone = "${format("%s%s", var.aws_region, "b")}"
  size = "${var.volume_size}"
  encrypted = "${var.volume_encrypted}"
  type = "gp2"

  tags {
    Name = "elasticsearch_volume_b"
    Stream = "${var.stream_tag}"
  }
}
