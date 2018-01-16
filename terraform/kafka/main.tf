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

resource "aws_security_group" "kafka" {
  name        = "kafka"
  description = "Kafka security group"
  vpc_id      = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.aws_bastion_vpc_cidr}"]
  }

  ingress {
    from_port   = 9092
    to_port     = 9092
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

resource "aws_iam_role" "kafka" {
  name = "kafka"

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

resource "aws_iam_role_policy" "kafka" {
  name = "kafka"
  role = "${aws_iam_role.kafka.id}"

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

resource "aws_iam_instance_profile" "kafka" {
  name = "kafka"
  role = "${aws_iam_role.kafka.name}"
}

data "aws_ami" "kafka" {
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

data "template_file" "kafka_a" {
  template = "${file("provision/kafka.tpl")}"

  vars {
    broker_id         = "1"
    aws_region        = "${var.aws_region}"
    security_groups   = "${aws_security_group.kafka.id}"
    environment       = "${var.environment}"
    bucket_name       = "${var.secrets_bucket_name}"
    consul_secret     = "${var.consul_secret}"
    consul_datacenter = "${var.consul_datacenter}"
    consul_nodes      = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "90")},${replace(var.aws_network_private_subnet_cidr_b, "0/24", "90")},${replace(var.aws_network_private_subnet_cidr_c, "0/24", "90")}"
    hosted_zone_name  = "${var.hosted_zone_name}"
    filebeat_version  = "${var.filebeat_version}"
    kafka_version     = "${var.kafka_version}"
    scala_version     = "${var.scala_version}"
    zookeeper_nodes   = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "20")},${replace(var.aws_network_private_subnet_cidr_b, "0/24", "20")},${replace(var.aws_network_private_subnet_cidr_c, "0/24", "20")}"
    hosted_zone_dns   = "${replace(var.aws_network_vpc_cidr, "0/16", "2")}"
  }
}

data "template_file" "kafka_b" {
  template = "${file("provision/kafka.tpl")}"

  vars {
    broker_id         = "2"
    aws_region        = "${var.aws_region}"
    security_groups   = "${aws_security_group.kafka.id}"
    environment       = "${var.environment}"
    bucket_name       = "${var.secrets_bucket_name}"
    consul_secret     = "${var.consul_secret}"
    consul_datacenter = "${var.consul_datacenter}"
    consul_nodes      = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "90")},${replace(var.aws_network_private_subnet_cidr_b, "0/24", "90")},${replace(var.aws_network_private_subnet_cidr_c, "0/24", "90")}"
    hosted_zone_name  = "${var.hosted_zone_name}"
    filebeat_version  = "${var.filebeat_version}"
    kafka_version     = "${var.kafka_version}"
    scala_version     = "${var.scala_version}"
    zookeeper_nodes   = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "20")},${replace(var.aws_network_private_subnet_cidr_b, "0/24", "20")},${replace(var.aws_network_private_subnet_cidr_c, "0/24", "20")}"
    hosted_zone_dns   = "${replace(var.aws_network_vpc_cidr, "0/16", "2")}"
  }
}

data "template_file" "kafka_c" {
  template = "${file("provision/kafka.tpl")}"

  vars {
    broker_id         = "3"
    aws_region        = "${var.aws_region}"
    security_groups   = "${aws_security_group.kafka.id}"
    environment       = "${var.environment}"
    bucket_name       = "${var.secrets_bucket_name}"
    consul_secret     = "${var.consul_secret}"
    consul_datacenter = "${var.consul_datacenter}"
    consul_nodes      = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "90")},${replace(var.aws_network_private_subnet_cidr_b, "0/24", "90")},${replace(var.aws_network_private_subnet_cidr_c, "0/24", "90")}"
    hosted_zone_name  = "${var.hosted_zone_name}"
    filebeat_version  = "${var.filebeat_version}"
    kafka_version     = "${var.kafka_version}"
    scala_version     = "${var.scala_version}"
    zookeeper_nodes   = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "20")},${replace(var.aws_network_private_subnet_cidr_b, "0/24", "20")},${replace(var.aws_network_private_subnet_cidr_c, "0/24", "20")}"
    hosted_zone_dns   = "${replace(var.aws_network_vpc_cidr, "0/16", "2")}"
  }
}

resource "aws_instance" "kafka_a" {
  ami                         = "${data.aws_ami.kafka.id}"
  instance_type               = "${var.kafka_instance_type}"
  subnet_id                   = "${data.terraform_remote_state.network.network-private-subnet-a-id}"
  private_ip                  = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "50")}"
  vpc_security_group_ids      = ["${aws_security_group.kafka.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.kafka.name}"
  user_data                   = "${data.template_file.kafka_a.rendered}"
  associate_public_ip_address = "false"
  key_name                    = "${var.key_name}"

  tags {
    Name   = "kafka-a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "kafka_b" {
  ami                         = "${data.aws_ami.kafka.id}"
  instance_type               = "${var.kafka_instance_type}"
  subnet_id                   = "${data.terraform_remote_state.network.network-private-subnet-b-id}"
  private_ip                  = "${replace(var.aws_network_private_subnet_cidr_b, "0/24", "50")}"
  vpc_security_group_ids      = ["${aws_security_group.kafka.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.kafka.name}"
  user_data                   = "${data.template_file.kafka_b.rendered}"
  associate_public_ip_address = "false"
  key_name                    = "${var.key_name}"

  tags {
    Name   = "kafka-b"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "kafka_c" {
  ami                         = "${data.aws_ami.kafka.id}"
  instance_type               = "${var.kafka_instance_type}"
  subnet_id                   = "${data.terraform_remote_state.network.network-private-subnet-c-id}"
  private_ip                  = "${replace(var.aws_network_private_subnet_cidr_c, "0/24", "50")}"
  vpc_security_group_ids      = ["${aws_security_group.kafka.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.kafka.name}"
  user_data                   = "${data.template_file.kafka_c.rendered}"
  associate_public_ip_address = "false"
  key_name                    = "${var.key_name}"

  tags {
    Name   = "kafka-c"
    Stream = "${var.stream_tag}"
  }
}
