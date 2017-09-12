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
    key = "pipeline.tfstate"
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

data "terraform_remote_state" "volumes" {
    backend = "s3"
    config {
        bucket = "nextbreakpoint-terraform-state"
        region = "${var.aws_region}"
        key = "volumes.tfstate"
    }
}

##############################################################################
# Pipeline server
##############################################################################

resource "aws_security_group" "pipeline_server" {
  name = "pipeline server"
  description = "pipeline server security group"
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

  ingress {
    from_port = 8081
    to_port = 8081
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 9000
    to_port = 9000
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  egress {
    from_port = 0
    to_port = 65535
    protocol = "udp"
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
    Name = "pipeline server security group"
    Stream = "${var.stream_tag}"
  }
}

data "template_file" "pipeline_server_user_data" {
  template = "${file("provision/pipeline.tpl")}"

  vars {
    aws_region              = "${var.aws_region}"
    environment             = "${var.environment}"
    security_groups         = "${aws_security_group.pipeline_server.id}"
    consul_log_file         = "${var.consul_log_file}"
    volume_name             = "${var.volume_name}"
    log_group_name          = "${var.log_group_name}"
    log_stream_name         = "${var.log_stream_name}"
    jenkins_host            = "${aws_instance.pipeline_server.private_ip}"
    sonarqube_host          = "${aws_instance.pipeline_server.private_ip}"
    artifactory_host        = "${aws_instance.pipeline_server.private_ip}"
    jenkins_version         = "${var.jenkins_version}"
    sonarqube_version       = "${var.sonarqube_version}"
    artifactory_version     = "${var.artifactory_version}"
    mysqlconnector_version  = "${var.mysqlconnector_version}"
    pipeline_data_dir       = "/mnt/pipeline"
  }
}

resource "aws_iam_instance_profile" "pipeline_server_profile" {
    name = "pipeline_server_profile"
    role = "${aws_iam_role.pipeline_server_role.name}"
}

resource "aws_iam_role" "pipeline_server_role" {
  name = "pipeline_server_role"

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

resource "aws_iam_role_policy" "pipeline_server_role_policy" {
  name = "pipeline_server_role_policy"
  role = "${aws_iam_role.pipeline_server_role.id}"

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

data "aws_ami" "pipeline" {
  most_recent = true

  filter {
    name = "name"
    values = ["pipeline-${var.base_version}-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["${var.account_id}"]
}

resource "aws_instance" "pipeline_server" {
  instance_type = "t2.medium"

  ami = "${data.aws_ami.pipeline.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-a-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.pipeline_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.pipeline_server_profile.id}"

  tags {
    Name = "pipeline_server"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_volume_attachment" "pipeline_volume_attachment_a" {
  device_name = "${var.volume_name}"
  volume_id = "${data.terraform_remote_state.volumes.pipeline-volume-a-id}"
  instance_id = "${aws_instance.pipeline_server.id}"
  skip_destroy = true
}

resource "null_resource" "pipeline_server" {
  depends_on = ["aws_volume_attachment.pipeline_volume_attachment_a"]

  triggers {
    cluster_instance_ids = "${join(",", aws_instance.pipeline_server.*.id)}"
  }

  connection {
    host = "${element(aws_instance.pipeline_server.*.private_ip, 0)}"
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
    bastion_user = "ec2-user"
    bastion_host = "bastion.${var.public_hosted_zone_name}"
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.pipeline_server_user_data.rendered}"
  }
}

##############################################################################
# Route 53
##############################################################################

resource "aws_route53_record" "jenkins" {
  zone_id = "${data.terraform_remote_state.vpc.hosted-zone-id}"
  name = "jenkins.${var.hosted_zone_name}"
  type = "A"
  ttl = "60"
  records = ["${aws_instance.pipeline_server.*.private_ip}"]
}

resource "aws_route53_record" "sonarqube" {
  zone_id = "${data.terraform_remote_state.vpc.hosted-zone-id}"
  name = "sonarqube.${var.hosted_zone_name}"
  type = "A"
  ttl = "60"
  records = ["${aws_instance.pipeline_server.*.private_ip}"]
}

resource "aws_route53_record" "artifactory" {
  zone_id = "${data.terraform_remote_state.vpc.hosted-zone-id}"
  name = "artifactory.${var.hosted_zone_name}"
  type = "A"
  ttl = "60"
  records = ["${aws_instance.pipeline_server.*.private_ip}"]
}
