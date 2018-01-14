##############################################################################
# Providers
##############################################################################

provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
  version = "~> 0.1"
}

provider "template" {
  version = "~> 0.1"
}

provider "local" {
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

resource "aws_iam_role" "openvpn" {
  name = "openvpn"

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
    },
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "openvpn" {
  name = "openvpn"
  role = "${aws_iam_role.openvpn.id}"

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
    },
    {
        "Action": [
            "s3:GetObject"
        ],
        "Effect": "Allow",
        "Resource": "arn:aws:s3:::${var.secrets_bucket_name}/*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "openvpn" {
  name = "openvpn"
  role = "${aws_iam_role.openvpn.name}"
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

data "aws_ami" "openvpn" {
  most_recent = true

  filter {
    name   = "name"
    values = ["openvpn-${var.base_version}-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["${var.account_id}"]
}

data "template_file" "openvpn" {
  template = "${file("provision/openvpn.tpl")}"

  vars {
    aws_region                 = "${var.aws_region}"
    environment                = "${var.environment}"
    bucket_name                = "${var.secrets_bucket_name}"
    openvpn_cidr               = "${var.openvpn_cidr}"
    openvpn_subnet             = "${replace(var.openvpn_cidr, "0/16", "0")}"
    hosted_zone_name           = "${var.hosted_zone_name}"
    aws_openvpn_subnet         = "${replace(var.aws_openvpn_vpc_cidr, "0/16", "0")}"
    aws_network_subnet         = "${replace(var.aws_network_vpc_cidr, "0/16", "0")}"
    aws_network_dns            = "${replace(var.aws_network_vpc_cidr, "0/16", "2")}"
  }
}

resource "aws_instance" "openvpn_a" {
  ami                         = "${data.aws_ami.openvpn.id}"
  instance_type               = "${var.openvpn_instance_type}"
  subnet_id                   = "${aws_subnet.openvpn_a.id}"
  vpc_security_group_ids      = ["${aws_security_group.openvpn.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.openvpn.id}"
  user_data                   = "${data.template_file.openvpn.rendered}"
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

data "template_file" "ca_cert" {
  template = "${file("../secrets/environments/production/openvpn/ca_cert.pem")}"
}

data "template_file" "client_key" {
  template = "${file("../secrets/environments/production/openvpn/client_key.pem")}"
}

data "template_file" "client_cert" {
  template = "${file("../secrets/environments/production/openvpn/client_cert.pem")}"
}

data "template_file" "ta_auth" {
  template = "${file("../secrets/environments/production/openvpn/ta.pem")}"
}

resource "local_file" "client_config" {
  content = <<EOF
client

proto udp
dev tun

remote openvpn.${var.hosted_zone_name} 1194

resolv-retry infinite

nobind

persist-key
persist-tun

remote-cert-tls server

key-direction 1

cipher AES-128-CBC

auth SHA256

comp-lzo

script-security 3

verb 3

explicit-exit-notify 1

<ca>
${data.template_file.ca_cert.rendered}</ca>
<key>
${data.template_file.client_key.rendered}</key>
<cert>
${data.template_file.client_cert.rendered}</cert>
<tls-auth>
${data.template_file.ta_auth.rendered}</tls-auth>
EOF

  filename = "../../secrets/openvpn_client.ovpn"
}

resource "local_file" "base_config" {
  content = <<EOF
client

proto udp
dev tun

remote openvpn.${var.hosted_zone_name} 1194

resolv-retry infinite

nobind

persist-key
persist-tun

remote-cert-tls server

key-direction 1

cipher AES-128-CBC

auth SHA256

comp-lzo

script-security 3

verb 3

explicit-exit-notify 1
EOF

  filename = "../../secrets/openvpn_base.conf"
}
