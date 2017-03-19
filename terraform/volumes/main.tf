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
  size = "${var.elasticsearch_volume_size}"
  encrypted = "${var.elasticsearch_volume_encrypted}"
  type = "gp2"

  tags {
    Name = "elasticsearch_volume_a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_ebs_volume" "elasticsearch_volume_b" {
  availability_zone = "${format("%s%s", var.aws_region, "b")}"
  size = "${var.elasticsearch_volume_size}"
  encrypted = "${var.elasticsearch_volume_encrypted}"
  type = "gp2"

  tags {
    Name = "elasticsearch_volume_b"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_ebs_volume" "pipeline_volume_a" {
  availability_zone = "${format("%s%s", var.aws_region, "a")}"
  size = "${var.pipeline_volume_size}"
  encrypted = "${var.pipeline_volume_encrypted}"
  type = "gp2"

  tags {
    Name = "pipeline_volume_a"
    Stream = "${var.stream_tag}"
  }
}
