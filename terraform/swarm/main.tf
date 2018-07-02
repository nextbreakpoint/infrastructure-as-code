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

data "template_file" "swarm-manager" {
  template = "${file("provision/swarm.tpl")}"

  vars {
    aws_region        = "${var.aws_region}"
    environment       = "${var.environment}"
    hosted_zone_name  = "${var.hosted_zone_name}"
    hosted_zone_dns   = "${replace(var.aws_network_vpc_cidr, "0/16", "2")}"
  }
}

data "template_file" "swarm-worker" {
  template = "${file("provision/swarm.tpl")}"

  vars {
    aws_region        = "${var.aws_region}"
    environment       = "${var.environment}"
    hosted_zone_name  = "${var.hosted_zone_name}"
    hosted_zone_dns   = "${replace(var.aws_network_vpc_cidr, "0/16", "2")}"
  }
}

resource "aws_instance" "swarm_manager_a" {
  ami                         = "${data.aws_ami.swarm.id}"
  instance_type               = "${var.swarm_instance_type}"
  subnet_id                   = "${data.terraform_remote_state.network.network-private-subnet-a-id}"
  private_ip                  = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "150")}"
  security_groups             = ["${aws_security_group.swarm.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.swarm.id}"
  user_data                   = "${data.template_file.swarm-manager.rendered}"
  associate_public_ip_address = "false"
  key_name                    = "${var.key_name}"

  tags {
    Name   = "swarm-manager-a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "swarm_manager_b" {
  ami                         = "${data.aws_ami.swarm.id}"
  instance_type               = "${var.swarm_instance_type}"
  subnet_id                   = "${data.terraform_remote_state.network.network-private-subnet-b-id}"
  private_ip                  = "${replace(var.aws_network_private_subnet_cidr_b, "0/24", "150")}"
  security_groups             = ["${aws_security_group.swarm.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.swarm.id}"
  user_data                   = "${data.template_file.swarm-manager.rendered}"
  associate_public_ip_address = "false"
  key_name                    = "${var.key_name}"

  tags {
    Name   = "swarm-manager-b"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "swarm_manager_c" {
  ami                         = "${data.aws_ami.swarm.id}"
  instance_type               = "${var.swarm_instance_type}"
  subnet_id                   = "${data.terraform_remote_state.network.network-private-subnet-c-id}"
  private_ip                  = "${replace(var.aws_network_private_subnet_cidr_c, "0/24", "150")}"
  security_groups             = ["${aws_security_group.swarm.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.swarm.id}"
  user_data                   = "${data.template_file.swarm-manager.rendered}"
  associate_public_ip_address = "false"
  key_name                    = "${var.key_name}"

  tags {
    Name   = "swarm-manager-c"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_launch_configuration" "swarm-worker" {
  name_prefix                 = "swarm-worker-"
  image_id                    = "${data.aws_ami.swarm.id}"
  instance_type               = "${var.swarm_instance_type}"
  security_groups             = ["${aws_security_group.swarm.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.swarm.id}"
  user_data                   = "${data.template_file.swarm-worker.rendered}"
  associate_public_ip_address = "false"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "swarm-worker" {
  name                      = "swarm-worker"
  max_size                  = 12
  min_size                  = 0
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = 0
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.swarm-worker.name}"
  vpc_zone_identifier       = ["${var.aws_subnet_private_a}", "${var.aws_subnet_private_b}", "${var.aws_subnet_private_c}"]

  lifecycle {
    create_before_destroy   = true
  }

  tag {
    key                     = "Name"
    value                   = "swarm-worker"
    propagate_at_launch     = true
  }

  timeouts {
    delete = "15m"
  }
}
