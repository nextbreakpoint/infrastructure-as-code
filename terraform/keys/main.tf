data "template_file" "bastion_public_key" {
  template = "${file("${var.keys_path}/${var.environment}-${var.colour}-bastion.pem.pub")}"
}

resource "aws_key_pair" "bastion" {
  key_name   = "${var.environment}-${var.colour}-bastion"
  public_key = "${data.template_file.bastion_public_key.rendered}"
}

data "template_file" "openvpn_public_key" {
  template = "${file("${var.keys_path}/${var.environment}-${var.colour}-openvpn.pem.pub")}"
}

resource "aws_key_pair" "openvpn" {
  key_name   = "${var.environment}-${var.colour}-openvpn"
  public_key = "${data.template_file.openvpn_public_key.rendered}"
}

data "template_file" "server_public_key" {
  template = "${file("${var.keys_path}/${var.environment}-${var.colour}-server.pem.pub")}"
}

resource "aws_key_pair" "server" {
  key_name   = "${var.environment}-${var.colour}-server"
  public_key = "${data.template_file.server_public_key.rendered}"
}

data "template_file" "packer_public_key" {
  template = "${file("${var.keys_path}/${var.environment}-${var.colour}-packer.pem.pub")}"
}

resource "aws_key_pair" "packer" {
  key_name   = "${var.environment}-${var.colour}-packer"
  public_key = "${data.template_file.packer_public_key.rendered}"
}
