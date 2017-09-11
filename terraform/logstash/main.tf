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
    key = "logstash.tfstate"
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
# Route 53
##############################################################################

resource "aws_route53_record" "logstash" {
   zone_id = "${data.terraform_remote_state.vpc.hosted-zone-id}"
   name = "logstash.${var.hosted_zone_name}"
   type = "A"
   ttl = "300"
   records = ["${aws_instance.logstash_server_a.private_ip}","${aws_instance.logstash_server_b.private_ip}"]
}

##############################################################################
# Logstash servers
##############################################################################

resource "aws_security_group" "logstash_server" {
  name = "logstash server"
  description = "logstash server security group"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.aws_bastion_vpc_cidr}"]
  }

  ingress {
    from_port = 5044
    to_port = 5044
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 8300
    to_port = 8302
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 8300
    to_port = 8302
    protocol = "udp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 9200
    to_port = 9400
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
    Name = "logstash server security group"
    Stream = "${var.stream_tag}"
  }
}

data "template_file" "logstash_server_user_data_a" {
  template = "${file("provision/logstash.tpl")}"

  vars {
    aws_region              = "${var.aws_region}"
    environment             = "${var.environment}"
    security_groups         = "${aws_security_group.logstash_server.id}"
    elasticsearch_host      = "elasticsearch.${var.hosted_zone_name}"
    consul_log_file         = "${var.consul_log_file}"
    log_group_name          = "${var.log_group_name}"
    log_stream_name         = "${var.log_stream_name}"
  }
}

data "template_file" "logstash_server_user_data_b" {
  template = "${file("provision/logstash.tpl")}"

  vars {
    aws_region              = "${var.aws_region}"
    environment             = "${var.environment}"
    security_groups         = "${aws_security_group.logstash_server.id}"
    elasticsearch_host      = "elasticsearch.${var.hosted_zone_name}"
    consul_log_file         = "${var.consul_log_file}"
    log_group_name          = "${var.log_group_name}"
    log_stream_name         = "${var.log_stream_name}"
  }
}

resource "aws_iam_instance_profile" "logstash_node_profile" {
    name = "logstash_node_profile"
    roles = ["${aws_iam_role.logstash_node_role.name}"]
}

resource "aws_iam_role" "logstash_node_role" {
  name = "logstash_node_role"

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

resource "aws_iam_role_policy" "logstash_node_role_policy" {
  name = "logstash_node_role_policy"
  role = "${aws_iam_role.logstash_node_role.id}"

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

data "aws_ami" "logstash" {
  most_recent = true

  filter {
    name = "name"
    values = ["logstash-${var.logstash_version}-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["${var.account_id}"]
}

resource "aws_instance" "logstash_server_a" {
  instance_type = "t2.small"

  ami = "${data.aws_ami.logstash.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-a-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.logstash_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.logstash_node_profile.name}"

  connection {
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
    bastion_user = "ec2-user"
    bastion_host = "bastion.${var.public_hosted_zone_name}"
  }

  tags {
    Name = "logstash_server_a"
    Stream = "${var.stream_tag}"
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.logstash_server_user_data_a.rendered}"
  }
}

resource "aws_instance" "logstash_server_b" {
  instance_type = "t2.small"

  ami = "${data.aws_ami.logstash.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-b-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.logstash_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.logstash_node_profile.name}"

  connection {
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
    bastion_user = "ec2-user"
    bastion_host = "bastion.${var.public_hosted_zone_name}"
  }

  tags {
    Name = "logstash_server_b"
    Stream = "${var.stream_tag}"
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.logstash_server_user_data_b.rendered}"
  }
}
