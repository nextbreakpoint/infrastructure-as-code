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
variable "bastion_user" {}
variable "bastion_host" {}
variable "instance_profile" {}

resource "aws_instance" "consul" {
  instance_type = "${var.instance_type}"

  ami = "${var.ami}"

  key_name = "${var.key_name}"

  security_groups = ["${var.security_groups}"]
  subnet_id = "${var.subnet}"

  associate_public_ip_address = "false"

  iam_instance_profile = "${var.instance_profile}"

  connection {
    user = "ubuntu"
    type = "ssh"
    private_key = "${file(var.key_path)}"
    bastion_user = "${var.bastion_user}"
    bastion_host = "${var.bastion_host}"
  }

  tags {
    Name = "${var.name}"
    stream = "${var.stream_tag}"
  }

  provisioner "remote-exec" {
    inline = "${var.user_data}"
  }
}
