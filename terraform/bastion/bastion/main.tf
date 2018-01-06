variable "name" {}
variable "stream_tag" {}
variable "ami" {}
variable "instance_type" {}
variable "key_path" {}
variable "key_name" {}
variable "security_groups" {}
variable "subnet_id" {}
variable "user_data" {}

resource "aws_instance" "bastion" {
  ami                         = "${var.ami}"
  instance_type               = "${var.instance_type}"
  vpc_security_group_ids      = ["${var.security_groups}"]
  subnet_id                   = "${var.subnet_id}"
  user_data                   = "${var.user_data}"
  key_name                    = "${var.key_name}"
  associate_public_ip_address = true
  # source_dest_check           = false

  tags = {
    Name   = "${var.name}"
    Stream = "${var.stream_tag}"
  }
}
