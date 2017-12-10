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
# openvpn servers
##############################################################################

resource "aws_security_group" "openvpn_server" {
  name = "openvpn-security-group"
  description = "openvpn security group"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

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

resource "aws_instance" "openvpn_server_a" {
  instance_type = "${var.openvpn_instance_type}"

  ami = "${var.openvpn_ami}"

  subnet_id = "${data.terraform_remote_state.vpc.network-public-subnet-a-id}"
  associate_public_ip_address = "true"
  security_groups = ["${aws_security_group.openvpn_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.openvpn_server_profile.name}"

  tags {
    Name = "openvpn-server-a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_route53_record" "openvpn" {
  zone_id = "${var.public_hosted_zone_id}"
  name = "openvpn.${var.public_hosted_zone_name}"
  type = "A"
  ttl = 60
  records = ["${aws_instance.openvpn_server_a.public_ip}"]
}
