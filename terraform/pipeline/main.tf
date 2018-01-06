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

##############################################################################
# Resources
##############################################################################

resource "aws_security_group" "pipeline" {
  name        = "pipeline"
  description = "Pipeline security group"
  vpc_id      = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.aws_bastion_vpc_cidr}"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.aws_bastion_vpc_cidr}"]
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

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
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

resource "aws_iam_role" "pipeline" {
  name = "pipeline"

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

resource "aws_iam_role_policy" "pipeline" {
  name = "pipeline"
  role = "${aws_iam_role.pipeline.id}"

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

resource "aws_iam_instance_profile" "pipeline" {
  name = "pipeline"
  role = "${aws_iam_role.pipeline.name}"
}

data "aws_ami" "pipeline" {
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

data "template_file" "pipeline" {
  template = "${file("provision/pipeline.tpl")}"

  vars {
    aws_region                 = "${var.aws_region}"
    environment                = "${var.environment}"
    bucket_name                = "${var.secrets_bucket_name}"
    consul_secret              = "${var.consul_secret}"
    consul_datacenter          = "${var.consul_datacenter}"
    consul_nodes               = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "90")},${replace(var.aws_network_private_subnet_cidr_b, "0/24", "90")},${replace(var.aws_network_private_subnet_cidr_c, "0/24", "90")}"
    volume_name                = "${var.volume_name}"
    filebeat_version           = "${var.filebeat_version}"
    jenkins_version            = "${var.jenkins_version}"
    sonarqube_version          = "${var.sonarqube_version}"
    artifactory_version        = "${var.artifactory_version}"
    mysqlconnector_version     = "${var.mysqlconnector_version}"
    mysql_root_password        = "${var.mysql_root_password}"
    mysql_sonarqube_password   = "${var.mysql_sonarqube_password}"
    mysql_artifactory_password = "${var.mysql_artifactory_password}"
    hosted_zone_dns            = "${replace(var.aws_network_vpc_cidr, "0/16", "2")}"
  }
}

resource "aws_instance" "pipeline_a" {
  instance_type               = "${var.pipeline_instance_type}"
  ami                         = "${data.aws_ami.pipeline.id}"
  private_ip                  = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "100")}"
  subnet_id                   = "${data.terraform_remote_state.network.network-private-subnet-a-id}"
  vpc_security_group_ids      = ["${aws_security_group.pipeline.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.pipeline.id}"
  user_data                   = "${data.template_file.pipeline.rendered}"
  key_name                    = "${var.key_name}"
  associate_public_ip_address = "false"

  ebs_block_device {
    device_name           = "${var.volume_name}"
    volume_size           = "${var.volume_size}"
    volume_type           = "gp2"
    encrypted             = "${var.volume_encrypted}"
    delete_on_termination = true
  }

  tags {
    Name   = "pipeline-a"
    Stream = "${var.stream_tag}"
  }
}
