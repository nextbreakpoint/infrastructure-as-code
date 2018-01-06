##############################################################################
# Providers
##############################################################################

provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
  version = "~> 0.1"
}

provider "template" {
  version = "~> 0.1"
}

##############################################################################
# Resources
##############################################################################

resource "aws_security_group" "consul" {
  name = "consul"
  description = "Consul security group"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.aws_bastion_vpc_cidr}"]
  }

  ingress {
    from_port = 8300
    to_port = 8300
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 8301
    to_port = 8302
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 8301
    to_port = 8302
    protocol = "udp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 8400
    to_port = 8400
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 8500
    to_port = 8500
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 8600
    to_port = 8600
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 8600
    to_port = 8600
    protocol = "udp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Stream = "${var.stream_tag}"
  }
}

resource "aws_iam_role" "consul" {
  name = "consul"

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

resource "aws_iam_role_policy" "consul" {
  name = "consul"
  role = "${aws_iam_role.consul.id}"

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

resource "aws_iam_instance_profile" "consul" {
    name = "consul"
    role = "${aws_iam_role.consul.name}"
}

data "aws_ami" "consul" {
  most_recent = true

  filter {
    name = "name"
    values = ["base-${var.base_version}-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["${var.account_id}"]
}

data "template_file" "consul" {
  template = "${file("provision/consul.tpl")}"

  vars {
    aws_region              = "${var.aws_region}"
    environment             = "${var.environment}"
    bucket_name             = "${var.secrets_bucket_name}"
    consul_secret           = "${var.consul_secret}"
    consul_datacenter       = "${var.consul_datacenter}"
    consul_master_token     = "${var.consul_master_token}"
    consul_nodes            = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "90")},${replace(var.aws_network_private_subnet_cidr_b, "0/24", "90")},${replace(var.aws_network_private_subnet_cidr_c, "0/24", "90")}"
    consul_bootstrap_expect = "3"
    filebeat_version        = "${var.filebeat_version}"
    hosted_zone_dns         = "${replace(var.aws_network_vpc_cidr, "0/16", "2")}"
  }
}

module "consul_a" {
  source = "./consul"

  name = "consul-a"
  region = "${var.aws_region}"
  ami = "${data.aws_ami.consul.id}"
  subnet = "${data.terraform_remote_state.network.network-private-subnet-a-id}"
  instance_type = "${var.consul_instance_type}"
  security_groups = "${aws_security_group.consul.id}"
  key_name = "${var.key_name}"
  key_path = "${var.key_path}"
  stream_tag = "${var.stream_tag}"
  user_data = "${data.template_file.consul.rendered}"
  instance_profile = "${aws_iam_instance_profile.consul.name}"
  private_ip = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "90")}"
}

module "consul_b" {
  source = "./consul"

  name = "consul-b"
  region = "${var.aws_region}"
  ami = "${data.aws_ami.consul.id}"
  subnet = "${data.terraform_remote_state.network.network-private-subnet-b-id}"
  instance_type = "${var.consul_instance_type}"
  security_groups = "${aws_security_group.consul.id}"
  key_name = "${var.key_name}"
  key_path = "${var.key_path}"
  stream_tag = "${var.stream_tag}"
  user_data = "${data.template_file.consul.rendered}"
  instance_profile = "${aws_iam_instance_profile.consul.name}"
  private_ip = "${replace(var.aws_network_private_subnet_cidr_b, "0/24", "90")}"
}

module "consul_c" {
  source = "./consul"

  name = "consul-c"
  region = "${var.aws_region}"
  ami = "${data.aws_ami.consul.id}"
  subnet = "${data.terraform_remote_state.network.network-private-subnet-c-id}"
  instance_type = "${var.consul_instance_type}"
  security_groups = "${aws_security_group.consul.id}"
  key_name = "${var.key_name}"
  key_path = "${var.key_path}"
  stream_tag = "${var.stream_tag}"
  user_data = "${data.template_file.consul.rendered}"
  instance_profile = "${aws_iam_instance_profile.consul.name}"
  private_ip = "${replace(var.aws_network_private_subnet_cidr_c, "0/24", "90")}"
}
