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

provider "template" {
  version = "~> 0.1"
}

provider "null" {
  version = "~> 0.1"
}

terraform {
  backend "s3" {
    bucket = "nextbreakpoint-terraform-state"
    region = "eu-west-1"
    key = "ecs.tfstate"
  }
}

##############################################################################
# Remote state
##############################################################################

data "terraform_remote_state" "vpc" {
    backend = "s3"
    config {
        bucket = "nextbreakpoint-terraform-state"
        region = "${var.aws_region}"
        key = "vpc.tfstate"
    }
}

data "terraform_remote_state" "network" {
    backend = "s3"
    config {
        bucket = "nextbreakpoint-terraform-state"
        region = "${var.aws_region}"
        key = "network.tfstate"
    }
}

##############################################################################
# ECS
##############################################################################

resource "aws_security_group" "cluster_server" {
  name = "cluster server"
  description = "cluster server security group"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.aws_bastion_vpc_cidr}"]
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  egress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
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
    Name = "cluster server security group"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_iam_instance_profile" "cluster_node_profile" {
    name = "ecs_node_profile"
    role = "${aws_iam_role.cluster_node_role.name}"
}

resource "aws_iam_role" "cluster_node_role" {
  name = "cluster_node_role"

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

resource "aws_iam_role_policy" "cluster_node_role_policy" {
  name = "cluster_node_role_policy"
  role = "${aws_iam_role.cluster_node_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:Submit*",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_ecs_cluster" "services" {
  name = "services"
}

resource "aws_instance" "cluster_node_a" {
  depends_on = ["aws_ecs_cluster.services"]
  instance_type = "${var.cluster_instance_type}"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.cluster_amis, var.aws_region)}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-a-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.cluster_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.cluster_node_profile.name}"

  connection {
    # The default username for our AMI
    user = "ec2-user"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
    bastion_user = "ec2-user"
    bastion_host = "bastion.nextbreakpoint.com"
  }

  provisioner "remote-exec" {
    inline = "echo 'ECS_CLUSTER=services' > /tmp/ecs.config; sudo mv /tmp/ecs.config /etc/ecs/ecs.config"
  }

  tags {
    Name = "cluster_server_a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "cluster_node_b" {
  depends_on = ["aws_ecs_cluster.services"]
  instance_type = "${var.cluster_instance_type}"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.cluster_amis, var.aws_region)}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-b-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.cluster_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.cluster_node_profile.name}"

  connection {
    # The default username for our AMI
    user = "ec2-user"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
    bastion_user = "ec2-user"
    bastion_host = "bastion.nextbreakpoint.com"
  }

  provisioner "remote-exec" {
    inline = "echo 'ECS_CLUSTER=services' > /tmp/ecs.config; sudo mv /tmp/ecs.config /etc/ecs/ecs.config"
  }

  tags {
    Name = "cluster_server_b"
    Stream = "${var.stream_tag}"
  }
}
