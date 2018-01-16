##############################################################################
# Providers
##############################################################################

provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
  version = "~> 0.1"
}

provider "terraform" {
  version = "~> 0.1"
}

provider "template" {
  version = "~> 0.1"
}

##############################################################################
# Resources
##############################################################################

resource "aws_security_group" "cassandra" {
  name        = "cassandra"
  description = "Cassandra security group"
  vpc_id      = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.aws_bastion_vpc_cidr}"]
  }

  ingress {
    from_port   = 7000
    to_port     = 7001
    protocol    = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port   = 7199
    to_port     = 7199
    protocol    = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port   = 9042
    to_port     = 9042
    protocol    = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port   = 9142
    to_port     = 9142
    protocol    = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port   = 9160
    to_port     = 9160
    protocol    = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port   = 8301
    to_port     = 8301
    protocol    = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port   = 8301
    to_port     = 8301
    protocol    = "udp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Stream = "${var.stream_tag}"
  }
}

resource "aws_iam_role" "cassandra" {
  name = "cassandra"

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

resource "aws_iam_role_policy" "cassandra" {
  name = "cassandra"
  role = "${aws_iam_role.cassandra.id}"

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

resource "aws_iam_instance_profile" "cassandra" {
  name = "cassandra"
  role = "${aws_iam_role.cassandra.name}"
}

data "aws_ami" "cassandra" {
  most_recent = true

  filter {
    name   = "name"
    values = ["base-${var.base_version}-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["${var.account_id}"]
}

data "template_file" "cassandra_seed" {
  template = "${file("provision/cassandra-seed.tpl")}"

  vars {
    security_groups   = "${aws_security_group.cassandra.id}"
    environment       = "${var.environment}"
    bucket_name       = "${var.secrets_bucket_name}"
    consul_datacenter = "${var.consul_datacenter}"
    consul_nodes      = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "90")},${replace(var.aws_network_private_subnet_cidr_b, "0/24", "90")},${replace(var.aws_network_private_subnet_cidr_c, "0/24", "90")}"
    consul_secret     = "${var.consul_secret}"
    hosted_zone_name  = "${var.hosted_zone_name}"
    filebeat_version  = "${var.filebeat_version}"
    cassandra_version = "${var.cassandra_version}"
    cassandra_nodes   = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "70")},${replace(var.aws_network_private_subnet_cidr_b, "0/24", "70")},${replace(var.aws_network_private_subnet_cidr_c, "0/24", "70")}"
    hosted_zone_dns   = "${replace(var.aws_network_vpc_cidr, "0/16", "2")}"
  }
}

data "template_file" "cassandra_node" {
  template = "${file("provision/cassandra-node.tpl")}"

  vars {
    security_groups   = "${aws_security_group.cassandra.id}"
    environment       = "${var.environment}"
    bucket_name       = "${var.secrets_bucket_name}"
    consul_datacenter = "${var.consul_datacenter}"
    consul_nodes      = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "90")},${replace(var.aws_network_private_subnet_cidr_b, "0/24", "90")},${replace(var.aws_network_private_subnet_cidr_c, "0/24", "90")}"
    consul_secret     = "${var.consul_secret}"
    hosted_zone_name  = "${var.hosted_zone_name}"
    filebeat_version  = "${var.filebeat_version}"
    cassandra_version = "${var.cassandra_version}"
    cassandra_nodes   = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "70")},${replace(var.aws_network_private_subnet_cidr_b, "0/24", "70")},${replace(var.aws_network_private_subnet_cidr_c, "0/24", "70")}"
    hosted_zone_dns   = "${replace(var.aws_network_vpc_cidr, "0/16", "2")}"
  }
}

resource "aws_instance" "cassandra_a1" {
  ami                         = "${data.aws_ami.cassandra.id}"
  instance_type               = "${var.cassandra_instance_type}"
  subnet_id                   = "${data.terraform_remote_state.network.network-private-subnet-a-id}"
  private_ip                  = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "70")}"
  vpc_security_group_ids      = ["${aws_security_group.cassandra.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.cassandra.id}"
  user_data                   = "${data.template_file.cassandra_seed.rendered}"
  associate_public_ip_address = "false"
  key_name                    = "${var.key_name}"

  tags {
    Name   = "cassandra-a1"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "cassandra_b1" {
  ami                         = "${data.aws_ami.cassandra.id}"
  instance_type               = "${var.cassandra_instance_type}"
  subnet_id                   = "${data.terraform_remote_state.network.network-private-subnet-b-id}"
  private_ip                  = "${replace(var.aws_network_private_subnet_cidr_b, "0/24", "70")}"
  vpc_security_group_ids      = ["${aws_security_group.cassandra.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.cassandra.id}"
  user_data                   = "${data.template_file.cassandra_seed.rendered}"
  associate_public_ip_address = "false"
  key_name                    = "${var.key_name}"

  tags {
    Name   = "cassandra-b1"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "cassandra_c1" {
  ami                         = "${data.aws_ami.cassandra.id}"
  instance_type               = "${var.cassandra_instance_type}"
  subnet_id                   = "${data.terraform_remote_state.network.network-private-subnet-c-id}"
  private_ip                  = "${replace(var.aws_network_private_subnet_cidr_c, "0/24", "70")}"
  vpc_security_group_ids      = ["${aws_security_group.cassandra.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.cassandra.id}"
  user_data                   = "${data.template_file.cassandra_seed.rendered}"
  associate_public_ip_address = "false"
  key_name                    = "${var.key_name}"

  tags {
    Name   = "cassandra-c1"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "cassandra_a2" {
  ami                         = "${data.aws_ami.cassandra.id}"
  instance_type               = "${var.cassandra_instance_type}"
  subnet_id                   = "${data.terraform_remote_state.network.network-private-subnet-a-id}"
  private_ip                  = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "72")}"
  vpc_security_group_ids      = ["${aws_security_group.cassandra.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.cassandra.id}"
  user_data                   = "${data.template_file.cassandra_node.rendered}"
  associate_public_ip_address = "false"
  key_name                    = "${var.key_name}"

  tags {
    Name   = "cassandra-a2"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "cassandra_b2" {
  ami                         = "${data.aws_ami.cassandra.id}"
  instance_type               = "${var.cassandra_instance_type}"
  subnet_id                   = "${data.terraform_remote_state.network.network-private-subnet-b-id}"
  private_ip                  = "${replace(var.aws_network_private_subnet_cidr_b, "0/24", "72")}"
  vpc_security_group_ids      = ["${aws_security_group.cassandra.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.cassandra.id}"
  user_data                   = "${data.template_file.cassandra_node.rendered}"
  associate_public_ip_address = "false"
  key_name                    = "${var.key_name}"

  tags {
    Name   = "cassandra-b2"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "cassandra_c2" {
  ami                         = "${data.aws_ami.cassandra.id}"
  instance_type               = "${var.cassandra_instance_type}"
  subnet_id                   = "${data.terraform_remote_state.network.network-private-subnet-c-id}"
  private_ip                  = "${replace(var.aws_network_private_subnet_cidr_c, "0/24", "72")}"
  vpc_security_group_ids      = ["${aws_security_group.cassandra.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.cassandra.id}"
  user_data                   = "${data.template_file.cassandra_node.rendered}"
  associate_public_ip_address = "false"
  key_name                    = "${var.key_name}"

  tags {
    Name   = "cassandra-c2"
    Stream = "${var.stream_tag}"
  }
}
