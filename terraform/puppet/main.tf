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

##############################################################################
# Puppet server
##############################################################################

resource "aws_security_group" "puppet_server" {
  name = "puppet-security-group"
  description = "Puppet security group"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.aws_bastion_vpc_cidr}"]
  }

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
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

data "template_file" "puppet_server_user_data" {
  template = "${file("provision/puppet.tpl")}"

  vars {
    aws_region              = "${var.aws_region}"
    environment             = "${var.environment}"
    security_groups         = "${aws_security_group.puppet_server.id}"
    consul_log_file         = "${var.consul_log_file}"
    log_group_name          = "${var.log_group_name}"
    log_stream_name         = "${var.log_stream_name}"
    logstash_host           = "logstash.${var.hosted_zone_name}"
  }
}

resource "aws_iam_instance_profile" "puppet_server_profile" {
    name = "puppet-server-profile"
    roles = ["${aws_iam_role.puppet_server_role.name}"]
}

resource "aws_iam_role" "puppet_server_role" {
  name = "puppet-server-role"

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

resource "aws_iam_role_policy" "puppet_server_role_policy" {
  name = "puppet-server-role-policy"
  role = "${aws_iam_role.puppet_server_role.id}"

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

data "aws_ami" "puppet" {
  most_recent = true

  filter {
    name = "name"
    values = ["puppet-${var.base_version}-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["${var.account_id}"]
}

resource "aws_instance" "puppet_server" {
  instance_type = "${var.puppet_instance_type}"

  ami = "${data.aws_ami.puppet.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-public-subnet-a-id}"
  associate_public_ip_address = "true"
  security_groups = ["${aws_security_group.puppet_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.puppet_server_profile.id}"

  connection {
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
  }

  tags {
    Name = "puppet-server-a"
    Stream = "${var.stream_tag}"
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.puppet_server_user_data.rendered}"
  }
}

##############################################################################
# Route 53
##############################################################################

resource "aws_route53_record" "puppet" {
  zone_id = "${data.terraform_remote_state.vpc.hosted-zone-id}"
  name = "puppet.${var.hosted_zone_name}"
  type = "A"

  alias {
    name = "${aws_instance.puppet_server.dns_name}"
    zone_id = "${aws_instance.puppet_server.zone_id}"
    evaluate_target_health = true
  }
}
