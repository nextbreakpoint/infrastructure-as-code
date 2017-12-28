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
  instance_type = "${var.instance_type}"

  ami = "${var.ami}"

  key_name = "${var.key_name}"

  security_groups = ["${var.security_groups}"]
  subnet_id = "${var.subnet}"

  associate_public_ip_address = "false"

  iam_instance_profile = "${var.instance_profile}"

  user_data = "${var.user_data}"

  private_ip = "${var.private_ip}"

  tags {
    Name = "${var.name}"
    Stream = "${var.stream_tag}"
  }
}
