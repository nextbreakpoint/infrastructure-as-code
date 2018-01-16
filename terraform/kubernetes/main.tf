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

resource "aws_security_group" "kubernetes" {
  name        = "kubernetes"
  description = "Kubernetes security group"
  vpc_id      = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.aws_bastion_vpc_cidr}"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
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

resource "aws_iam_role" "kubernetes" {
  name = "kubernetes"

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

resource "aws_iam_role_policy" "kubernetes" {
  name = "kubernetes"
  role = "${aws_iam_role.kubernetes.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
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

resource "aws_iam_instance_profile" "kubernetes" {
  name = "kubernetes-server-profile"
  role = "${aws_iam_role.kubernetes.name}"
}

data "aws_ami" "kubernetes" {
  most_recent = true

  filter {
    name   = "name"
    values = ["kubernetes-${var.kubernetes_version}-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "template_file" "kubernetes_master_a" {
  template = "${file("provision/kubernetes-master.tpl")}"

  vars {
    aws_region        = "${var.aws_region}"
    environment       = "${var.environment}"
    bucket_name       = "${var.secrets_bucket_name}"
    security_groups   = "${aws_security_group.kubernetes.id}"
    consul_secret     = "${var.consul_secret}"
    consul_datacenter = "${var.consul_datacenter}"
    consul_nodes      = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "90")},${replace(var.aws_network_private_subnet_cidr_b, "0/24", "90")},${replace(var.aws_network_private_subnet_cidr_c, "0/24", "90")}"
    hosted_zone_name  = "${var.hosted_zone_name}"
    filebeat_version  = "${var.filebeat_version}"
    kubernetes_token  = "${var.kubernetes_token}"
    pod_network_cidr  = "${var.kubernetes_pod_network_cidr}"
    hosted_zone_dns   = "${replace(var.aws_network_vpc_cidr, "0/16", "2")}"
  }
}

data "template_file" "kubernetes_master_b" {
  template = "${file("provision/kubernetes-master.tpl")}"

  vars {
    aws_region        = "${var.aws_region}"
    environment       = "${var.environment}"
    bucket_name       = "${var.secrets_bucket_name}"
    security_groups   = "${aws_security_group.kubernetes.id}"
    consul_datacenter = "${var.consul_datacenter}"
    consul_secret     = "${var.consul_secret}"
    consul_nodes      = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "90")},${replace(var.aws_network_private_subnet_cidr_b, "0/24", "90")},${replace(var.aws_network_private_subnet_cidr_c, "0/24", "90")}"
    hosted_zone_name  = "${var.hosted_zone_name}"
    filebeat_version  = "${var.filebeat_version}"
    kubernetes_token  = "${var.kubernetes_token}"
    pod_network_cidr  = "${var.kubernetes_pod_network_cidr}"
    hosted_zone_dns   = "${replace(var.aws_network_vpc_cidr, "0/16", "2")}"
  }
}

data "template_file" "kubernetes_worker_a" {
  template = "${file("provision/kubernetes-node.tpl")}"

  vars {
    aws_region             = "${var.aws_region}"
    environment            = "${var.environment}"
    bucket_name            = "${var.secrets_bucket_name}"
    security_groups        = "${aws_security_group.kubernetes.id}"
    consul_secret          = "${var.consul_secret}"
    consul_datacenter      = "${var.consul_datacenter}"
    consul_nodes           = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "90")},${replace(var.aws_network_private_subnet_cidr_b, "0/24", "90")},${replace(var.aws_network_private_subnet_cidr_c, "0/24", "90")}"
    hosted_zone_name       = "${var.hosted_zone_name}"
    filebeat_version       = "${var.filebeat_version}"
    kubernetes_master_ip   = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "200")}"
    kubernetes_master_port = "6443"
    kubernetes_token       = "${var.kubernetes_token}"
    hosted_zone_dns        = "${replace(var.aws_network_vpc_cidr, "0/16", "2")}"
  }
}

data "template_file" "kubernetes_worker_b" {
  template = "${file("provision/kubernetes-node.tpl")}"

  vars {
    aws_region             = "${var.aws_region}"
    environment            = "${var.environment}"
    bucket_name            = "${var.secrets_bucket_name}"
    security_groups        = "${aws_security_group.kubernetes.id}"
    consul_secret          = "${var.consul_secret}"
    consul_datacenter      = "${var.consul_datacenter}"
    consul_nodes           = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "90")},${replace(var.aws_network_private_subnet_cidr_b, "0/24", "90")},${replace(var.aws_network_private_subnet_cidr_c, "0/24", "90")}"
    hosted_zone_name       = "${var.hosted_zone_name}"
    filebeat_version       = "${var.filebeat_version}"
    kubernetes_master_ip   = "${replace(var.aws_network_private_subnet_cidr_b, "0/24", "200")}"
    kubernetes_master_port = "6443"
    kubernetes_token       = "${var.kubernetes_token}"
    hosted_zone_dns        = "${replace(var.aws_network_vpc_cidr, "0/16", "2")}"
  }
}

resource "aws_instance" "kubernetes_a" {
  ami                         = "${data.aws_ami.kubernetes.id}"
  instance_type               = "${var.kubernetes_instance_type}"
  private_ip                  = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "200")}"
  subnet_id                   = "${data.terraform_remote_state.network.network-private-subnet-a-id}"
  vpc_security_group_ids      = ["${aws_security_group.kubernetes.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.kubernetes.name}"
  user_data                   = "${data.template_file.kubernetes_master_a.rendered}"
  associate_public_ip_address = "false"
  key_name                    = "${var.key_name}"

  tags {
    Name   = "kubernetes-master-a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_launch_configuration" "kubernetes" {
  name_prefix                 = "kubernetes-"
  image_id                    = "${data.aws_ami.kubernetes.id}"
  instance_type               = "${var.kubernetes_instance_type}"
  security_groups             = ["${aws_security_group.kubernetes.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.kubernetes.name}"
  user_data                   = "${data.template_file.kubernetes_worker_a.rendered}"
  associate_public_ip_address = "false"
  key_name                    = "${var.key_name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "kubernetes" {
  name                      = "kubernetes"
  max_size                  = 4
  min_size                  = 0
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.kubernetes.name}"

  vpc_zone_identifier = [
    "${data.terraform_remote_state.network.network-private-subnet-a-id}",
  ]

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Stream"
    value               = "${var.stream_tag}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "kubernetes"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }
}
