##############################################################################
# Providers
##############################################################################

provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
  version = "~> 0.1"
}

##############################################################################
# Resources
##############################################################################

resource "aws_security_group" "openvpn" {
  name        = "openvpn"
  description = "OpenVPN security group"
  vpc_id      = "${data.terraform_remote_state.vpc.openvpn-vpc-id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 943
    to_port     = 943
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["${data.terraform_remote_state.vpc.network-vpc-cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Stream = "${var.stream_tag}"
  }
}

resource "aws_route_table" "openvpn" {
  vpc_id = "${data.terraform_remote_state.vpc.openvpn-vpc-id}"

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.network-to-openvpn-peering-connection-id}"
    cidr_block                = "${data.terraform_remote_state.vpc.network-vpc-cidr}"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${data.terraform_remote_state.vpc.openvpn-internet-gateway-id}"
  }

  tags {
    Name   = "openvpn"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_subnet" "openvpn_a" {
  vpc_id                  = "${data.terraform_remote_state.vpc.openvpn-vpc-id}"
  availability_zone       = "${format("%s%s", var.aws_region, "a")}"
  cidr_block              = "${var.aws_openvpn_subnet_cidr_a}"
  map_public_ip_on_launch = true

  tags {
    Name   = "openvpn-a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_subnet" "openvpn_b" {
  vpc_id                  = "${data.terraform_remote_state.vpc.openvpn-vpc-id}"
  availability_zone       = "${format("%s%s", var.aws_region, "b")}"
  cidr_block              = "${var.aws_openvpn_subnet_cidr_b}"
  map_public_ip_on_launch = true

  tags {
    Name   = "openvpn-b"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_route_table_association" "openvpn_a" {
  subnet_id      = "${aws_subnet.openvpn_a.id}"
  route_table_id = "${aws_route_table.openvpn.id}"
}

resource "aws_route_table_association" "openvpn_b" {
  subnet_id      = "${aws_subnet.openvpn_b.id}"
  route_table_id = "${aws_route_table.openvpn.id}"
}

resource "aws_instance" "openvpn_a" {
  ami                         = "${var.openvpn_ami}"
  instance_type               = "${var.openvpn_instance_type}"
  subnet_id                   = "${aws_subnet.openvpn_a.id}"
  vpc_security_group_ids      = ["${aws_security_group.openvpn.id}"]
  associate_public_ip_address = "true"
  source_dest_check           = false
  key_name                    = "${var.key_name}"

  tags {
    Name   = "openvpn-a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_route53_record" "openvpn" {
  zone_id = "${var.hosted_zone_id}"
  name    = "openvpn.${var.hosted_zone_name}"
  type    = "A"
  ttl     = 60
  records = ["${aws_instance.openvpn_a.public_ip}"]
}
