##############################################################################
# Provider
##############################################################################

provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
  version = "~> 0.1"
}

##############################################################################
# Security Groups
##############################################################################

resource "aws_security_group" "openvpn_server" {
  name = "openvpn-security-group"
  description = "OpenVPN security group"
  vpc_id = "${data.terraform_remote_state.vpc.openvpn-vpc-id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 1194
    to_port = 1194
    protocol = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 943
    to_port = 943
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Stream = "${var.stream_tag}"
  }
}

##############################################################################
# Profiles
##############################################################################

resource "aws_iam_instance_profile" "openvpn_server_profile" {
    name = "openvpn-server-profile"
    role = "${aws_iam_role.openvpn_server_role.name}"
}

resource "aws_iam_role" "openvpn_server_role" {
  name = "openvpn-server-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "openvpn_server_role_policy" {
  name = "openvpn-server-role-policy"
  role = "${aws_iam_role.openvpn_server_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:DescribeInstances"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

##############################################################################
# Subnets
##############################################################################

resource "aws_route_table" "openvpn" {
  vpc_id = "${data.terraform_remote_state.vpc.openvpn-vpc-id}"

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.network-to-openvpn-peering-connection-id}"
    cidr_block = "${data.terraform_remote_state.vpc.network-vpc-cidr}"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${data.terraform_remote_state.vpc.openvpn-internet-gateway-id}"
  }

  tags {
    Name = "openvpn-route-table"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_subnet" "openvpn_a" {
  vpc_id = "${data.terraform_remote_state.vpc.openvpn-vpc-id}"
  availability_zone = "${format("%s%s", var.aws_region, "a")}"
  cidr_block = "${var.aws_openvpn_subnet_cidr_a}"

  tags {
    Name = "openvpn-subnet-a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_subnet" "openvpn_b" {
  vpc_id = "${data.terraform_remote_state.vpc.openvpn-vpc-id}"
  availability_zone = "${format("%s%s", var.aws_region, "b")}"
  cidr_block = "${var.aws_openvpn_subnet_cidr_b}"

  tags {
    Name = "openvpn-subnet-b"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_route_table_association" "openvpn_a" {
  subnet_id = "${aws_subnet.openvpn_a.id}"
  route_table_id = "${aws_route_table.openvpn.id}"
}

resource "aws_route_table_association" "openvpn_b" {
  subnet_id = "${aws_subnet.openvpn_b.id}"
  route_table_id = "${aws_route_table.openvpn.id}"
}

##############################################################################
# OpenVPN Servers
##############################################################################

resource "aws_instance" "openvpn_server_a" {
  instance_type = "${var.openvpn_instance_type}"

  ami = "${var.openvpn_ami}"

  subnet_id = "${aws_subnet.openvpn_a.id}"
  associate_public_ip_address = "true"
  security_groups = ["${aws_security_group.openvpn_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.openvpn_server_profile.name}"

  tags {
    Name = "openvpn-server-a"
    Stream = "${var.stream_tag}"
  }
}

##############################################################################
# Route53
##############################################################################

resource "aws_route53_record" "openvpn" {
  zone_id = "${var.public_hosted_zone_id}"
  name = "openvpn.${var.public_hosted_zone_name}"
  type = "A"
  ttl = 60
  records = ["${aws_instance.openvpn_server_a.public_ip}"]
}
