variable "name" {}
variable "ami" {}
variable "instance_type" {}
variable "region" {}
variable "subnet" {}
variable "security_groups" {}
variable "key_name" {}
variable "key_path" {}
variable "stream_tag" {}
variable "user_data" {}
variable "instance_profile" {}
variable "private_ip" {}

resource "aws_instance" "consul" {
  ami                         = "${var.ami}"
  instance_type               = "${var.instance_type}"
  subnet_id                   = "${var.subnet}"
  private_ip                  = "${var.private_ip}"
  vpc_security_group_ids      = ["${var.security_groups}"]
  iam_instance_profile        = "${var.instance_profile}"
  user_data                   = "${var.user_data}"
  key_name                    = "${var.key_name}"
  associate_public_ip_address = "false"

  tags {
    Name   = "${var.name}"
    Stream = "${var.stream_tag}"
  }
}
