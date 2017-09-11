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

terraform {
  backend "s3" {
    bucket = "nextbreakpoint-terraform-state"
    region = "eu-west-1"
    key = "consul.tfstate"
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
# Consul servers
##############################################################################

resource "aws_security_group" "consul_server" {
  name = "consul server"
  description = "Consul server, UI and maintenance"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.aws_bastion_vpc_cidr}"]
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
    from_port = 8400
    to_port = 8400
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 8500
    to_port = 8500
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 8600
    to_port = 8600
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 8600
    to_port = 8600
    protocol = "udp"
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

  tags {
    Name = "consul server security group"
    stream = "${var.stream_tag}"
  }
}

data "template_file" "consul_server_user_data" {
  template = "${file("provision/consul.tpl")}"

  vars {
    aws_region              = "${var.aws_region}"
    environment             = "${var.environment}"
    consul_log_file         = "${var.consul_log_file}"
    log_group_name          = "${var.log_group_name}"
    log_stream_name         = "${var.log_stream_name}"
    bootstrap_expect        = "3"
  }
}

resource "aws_iam_instance_profile" "consul_node_profile" {
    name = "consul_node_profile"
    role = "${aws_iam_role.consul_node_role.name}"
}

resource "aws_iam_role" "consul_node_role" {
  name = "consul_node_role"

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

resource "aws_iam_role_policy" "consul_node_role_policy" {
  name = "consul_node_role_policy"
  role = "${aws_iam_role.consul_node_role.id}"

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

data "aws_ami" "consul" {
  most_recent = true

  filter {
    name = "name"
    values = ["base-${var.base_version}-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["${var.account_id}"]
}

module "consul_servers_a" {
  source = "./consul"

  name = "consul_server_a"
  region = "${var.aws_region}"
  ami = "${data.aws_ami.consul.id}"
  subnet = "${data.terraform_remote_state.vpc.network-private-subnet-a-id}"
  instance_type = "t2.micro"
  security_groups = "${aws_security_group.consul_server.id}"
  key_name = "${var.key_name}"
  key_path = "${var.key_path}"
  stream_tag = "${var.stream_tag}"
  user_data = "${data.template_file.consul_server_user_data.rendered}"
  bastion_user = "ec2-user"
  bastion_host = "bastion.${var.public_hosted_zone_name}"
  instance_profile = "${aws_iam_instance_profile.consul_node_profile.name}"
}

module "consul_servers_b" {
  source = "./consul"

  name = "consul_server_b"
  region = "${var.aws_region}"
  ami = "${data.aws_ami.consul.id}"
  subnet = "${data.terraform_remote_state.vpc.network-private-subnet-b-id}"
  instance_type = "t2.micro"
  security_groups = "${aws_security_group.consul_server.id}"
  key_name = "${var.key_name}"
  key_path = "${var.key_path}"
  stream_tag = "${var.stream_tag}"
  user_data = "${data.template_file.consul_server_user_data.rendered}"
  bastion_user = "ec2-user"
  bastion_host = "bastion.${var.public_hosted_zone_name}"
  instance_profile = "${aws_iam_instance_profile.consul_node_profile.name}"
}

module "consul_servers_c" {
  source = "./consul"

  name = "consul_server_c"
  region = "${var.aws_region}"
  ami = "${data.aws_ami.consul.id}"
  subnet = "${data.terraform_remote_state.vpc.network-private-subnet-c-id}"
  instance_type = "t2.micro"
  security_groups = "${aws_security_group.consul_server.id}"
  key_name = "${var.key_name}"
  key_path = "${var.key_path}"
  stream_tag = "${var.stream_tag}"
  user_data = "${data.template_file.consul_server_user_data.rendered}"
  bastion_user = "ec2-user"
  bastion_host = "bastion.${var.public_hosted_zone_name}"
  instance_profile = "${aws_iam_instance_profile.consul_node_profile.name}"
}

##############################################################################
# Load balancer
##############################################################################

resource "aws_security_group" "consul_elb" {
  name = "consul elb"
  description = "consul load balacer"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port = 8500
    to_port = 8500
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "consul elb security group"
    stream = "${var.stream_tag}"
  }
}

resource "aws_elb" "consul" {
  name = "consul-elb"
  security_groups = ["${aws_security_group.consul_elb.id}"]
  subnets = ["${data.terraform_remote_state.vpc.network-private-subnet-a-id}","${data.terraform_remote_state.vpc.network-private-subnet-b-id}","${data.terraform_remote_state.vpc.network-private-subnet-c-id}"]

  listener {
    instance_port = 8500
    instance_protocol = "http"
    lb_port = 8500
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 3
    timeout = 10
    target = "TCP:8500"
    interval = 30
  }

  instances = ["${module.consul_servers_a.ids}", "${module.consul_servers_b.ids}", "${module.consul_servers_c.ids}"]
  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400
  internal = true

  tags {
    Name = "consul elb"
    stream = "${var.stream_tag}"
  }
}

##############################################################################
# Route 53
##############################################################################

resource "aws_route53_record" "consul" {
  zone_id = "${data.terraform_remote_state.vpc.hosted-zone-id}"
  name = "consul.${var.hosted_zone_name}"
  type = "A"

  alias {
    name = "${aws_elb.consul.dns_name}"
    zone_id = "${aws_elb.consul.zone_id}"
    evaluate_target_health = true
  }
}
