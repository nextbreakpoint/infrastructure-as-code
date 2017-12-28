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
  instance_type = "${var.instance_type}"

  ami = "${var.ami}"

  key_name = "${var.key_name}"

  security_groups = ["${var.security_groups}"]
  subnet_id = "${var.subnet_id}"
  source_dest_check = false

  associate_public_ip_address = true

  user_data = "${var.user_data}"

  connection {
    user = "ec2-user"
    type = "ssh"
    private_key = "${file(var.key_path)}"
  }

  tags = {
    Name = "${var.name}"
    Stream = "${var.stream_tag}"
  }
}
