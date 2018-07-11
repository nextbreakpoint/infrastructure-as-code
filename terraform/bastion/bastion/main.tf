variable "environment" {}
variable "colour" {}
variable "name" {}
variable "ami" {}
variable "instance_type" {}
variable "security_groups" {}
variable "subnet_id" {}
variable "key_name" {}
variable "user_data" {}

resource "aws_instance" "bastion" {
  ami                         = "${var.ami}"
  instance_type               = "${var.instance_type}"
  vpc_security_group_ids      = ["${var.security_groups}"]
  subnet_id                   = "${var.subnet_id}"
  user_data                   = "${var.user_data}"
  key_name                    = "${var.key_name}"
  associate_public_ip_address = true

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.name}"
  }
}
