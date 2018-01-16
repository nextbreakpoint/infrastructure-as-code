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

resource "aws_security_group" "swarm" {
  name        = "swarm"
  description = "Swarm security group"
  vpc_id      = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.aws_bastion_vpc_cidr}"]
  }

  ingress {
    from_port   = 2376
    to_port     = 2376
    protocol    = "tcp"
    cidr_blocks = ["${var.aws_bastion_vpc_cidr}"]
  }

  ingress {
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    cidr_blocks = ["${var.aws_bastion_vpc_cidr}"]
  }

  ingress {
    from_port   = 7946
    to_port     = 7946
    protocol    = "tcp"
    cidr_blocks = ["${var.aws_bastion_vpc_cidr}"]
  }

  ingress {
    from_port   = 7946
    to_port     = 7946
    protocol    = "udp"
    cidr_blocks = ["${var.aws_bastion_vpc_cidr}"]
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

resource "aws_iam_role" "swarm" {
  name = "swarm"

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

resource "aws_iam_role_policy" "swarm" {
  name = "swarm"
  role = "${aws_iam_role.swarm.id}"

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

resource "aws_iam_instance_profile" "swarm" {
  name = "swarm"
  role = "${aws_iam_role.swarm.name}"
}

data "aws_ami" "swarm" {
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

data "template_file" "swarm" {
  template = "${file("provision/swarm.tpl")}"

  vars {
    aws_region        = "${var.aws_region}"
    environment       = "${var.environment}"
    bucket_name       = "${var.secrets_bucket_name}"
    cluster_name      = "${aws_ecs_cluster.services.name}"
    consul_secret     = "${var.consul_secret}"
    consul_datacenter = "${var.consul_datacenter}"
    consul_nodes      = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "90")},${replace(var.aws_network_private_subnet_cidr_b, "0/24", "90")},${replace(var.aws_network_private_subnet_cidr_c, "0/24", "90")}"
    filebeat_version  = "${var.filebeat_version}"
    security_groups   = "${aws_security_group.swarm.id}"
    hosted_zone_name  = "${var.hosted_zone_name}"
    hosted_zone_dns   = "${replace(var.aws_network_vpc_cidr, "0/16", "2")}"
  }
}

resource "aws_instance" "swarm_master_a" {
  ami                         = "${data.aws_ami.swarm.id}"
  instance_type               = "${var.swarm_instance_type}"
  subnet_id                   = "${data.terraform_remote_state.network.network-private-subnet-a-id}"
  private_ip                  = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "150")}"
  security_groups             = ["${aws_security_group.swarm.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.swarm.id}"
  user_data                   = "${data.template_file.swarm.rendered}"
  associate_public_ip_address = "false"
  key_name                    = "${var.key_name}"

  tags {
    Name   = "swarm-master-a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "swarm_worker1_a" {
  ami                         = "${data.aws_ami.swarm.id}"
  instance_type               = "${var.swarm_instance_type}"
  subnet_id                   = "${data.terraform_remote_state.network.network-private-subnet-a-id}"
  private_ip                  = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "151")}"
  security_groups             = ["${aws_security_group.swarm.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.swarm.id}"
  user_data                   = "${data.template_file.swarm.rendered}"
  associate_public_ip_address = "false"
  key_name                    = "${var.key_name}"

  tags {
    Name   = "swarm-worker1-a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "swarm_worker2_a" {
  ami                         = "${data.aws_ami.swarm.id}"
  instance_type               = "${var.swarm_instance_type}"
  subnet_id                   = "${data.terraform_remote_state.network.network-private-subnet-a-id}"
  private_ip                  = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "152")}"
  security_groups             = ["${aws_security_group.swarm.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.swarm.id}"
  user_data                   = "${data.template_file.swarm.rendered}"
  associate_public_ip_address = "false"
  key_name                    = "${var.key_name}"

  tags {
    Name   = "swarm-worker2-a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "swarm_master_b" {
  ami                         = "${data.aws_ami.swarm.id}"
  instance_type               = "${var.swarm_instance_type}"
  subnet_id                   = "${data.terraform_remote_state.network.network-private-subnet-b-id}"
  private_ip                  = "${replace(var.aws_network_private_subnet_cidr_b, "0/24", "150")}"
  vpc_security_group_ids      = ["${aws_security_group.swarm.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.swarm.id}"
  user_data                   = "${data.template_file.swarm.rendered}"
  associate_public_ip_address = "false"
  key_name                    = "${var.key_name}"

  tags {
    Name   = "swarm-master-b"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "swarm_worker1_b" {
  ami                         = "${data.aws_ami.swarm.id}"
  instance_type               = "${var.swarm_instance_type}"
  subnet_id                   = "${data.terraform_remote_state.network.network-private-subnet-b-id}"
  private_ip                  = "${replace(var.aws_network_private_subnet_cidr_b, "0/24", "151")}"
  vpc_security_group_ids      = ["${aws_security_group.swarm.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.swarm.id}"
  user_data                   = "${data.template_file.swarm.rendered}"
  associate_public_ip_address = "false"
  key_name                    = "${var.key_name}"

  tags {
    Name   = "swarm-worker1-b"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "swarm_worker2_b" {
  ami                         = "${data.aws_ami.swarm.id}"
  instance_type               = "${var.swarm_instance_type}"
  subnet_id                   = "${data.terraform_remote_state.network.network-private-subnet-b-id}"
  private_ip                  = "${replace(var.aws_network_private_subnet_cidr_b, "0/24", "152")}"
  vpc_security_group_ids      = ["${aws_security_group.swarm.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.swarm.id}"
  user_data                   = "${data.template_file.swarm.rendered}"
  associate_public_ip_address = "false"
  key_name                    = "${var.key_name}"

  tags {
    Name   = "swarm-worker2-b"
    Stream = "${var.stream_tag}"
  }
}
