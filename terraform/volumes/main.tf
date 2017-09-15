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
# Volumes
##############################################################################

resource "aws_ebs_volume" "elasticsearch_volume_a" {
  availability_zone = "${format("%s%s", var.aws_region, "a")}"
  size = "${var.elasticsearch_volume_size}"
  encrypted = "${var.elasticsearch_volume_encrypted}"
  type = "gp2"

  tags {
    Name = "elasticsearch-volume-a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_ebs_volume" "elasticsearch_volume_b" {
  availability_zone = "${format("%s%s", var.aws_region, "b")}"
  size = "${var.elasticsearch_volume_size}"
  encrypted = "${var.elasticsearch_volume_encrypted}"
  type = "gp2"

  tags {
    Name = "elasticsearch-volume-b"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_ebs_volume" "pipeline_volume_a" {
  availability_zone = "${format("%s%s", var.aws_region, "a")}"
  size = "${var.pipeline_volume_size}"
  encrypted = "${var.pipeline_volume_encrypted}"
  type = "gp2"

  tags {
    Name = "pipeline-volume-a"
    Stream = "${var.stream_tag}"
  }
}
