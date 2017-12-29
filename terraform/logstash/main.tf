##############################################################################
# Provider
##############################################################################

provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
  version = "~> 0.1"
}

provider "template" {
  version = "~> 0.1"
}

##############################################################################
# Logstash servers
##############################################################################

resource "aws_security_group" "logstash_server" {
  name = "logstash-security-group"
  description = "Logstash security group"
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
    from_port = 8301
    to_port = 8301
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 8301
    to_port = 8301
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

data "template_file" "logstash_server_user_data" {
  template = "${file("provision/logstash.tpl")}"

  vars {
    aws_region              = "${var.aws_region}"
    environment             = "${var.environment}"
    bucket_name             = "${var.secrets_bucket_name}"
    consul_secret           = "${var.consul_secret}"
    consul_datacenter       = "${var.consul_datacenter}"
    consul_nodes            = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "90")},${replace(var.aws_network_private_subnet_cidr_b, "0/24", "90")},${replace(var.aws_network_private_subnet_cidr_c, "0/24", "90")}"
    consul_logfile          = "${var.consul_logfile}"
    cluster_name            = "${var.elasticsearch_cluster_name}"
    elasticsearch_version   = "${var.elasticsearch_version}"
    logstash_version        = "${var.logstash_version}"
    filebeat_version        = "${var.filebeat_version}"
    minimum_master_nodes    = "${var.minimum_master_nodes}"
    elasticsearch_nodes     = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "10")},${replace(var.aws_network_private_subnet_cidr_b, "0/24", "10")}"
    logstash_password       = "${var.logstash_password}"
    elasticsearch_password  = "${var.elasticsearch_password}"
  }
}

resource "aws_iam_instance_profile" "logstash_server_profile" {
    name = "logstash-server-profile"
    role = "${aws_iam_role.logstash_server_role.name}"
}

resource "aws_iam_role" "logstash_server_role" {
  name = "logstash-server-role"

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

resource "aws_iam_role_policy" "logstash_server_role_policy" {
  name = "logstash-server-role-policy"
  role = "${aws_iam_role.logstash_server_role.id}"

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

data "aws_ami" "logstash" {
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

/*
resource "aws_instance" "logstash_server_a" {
  instance_type = "${var.logstash_instance_type}"

  ami = "${data.aws_ami.logstash.id}"

  subnet_id = "${data.terraform_remote_state.network.network-private-subnet-a-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.logstash_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.logstash_server_profile.name}"

  user_data = "${data.template_file.logstash_server_user_data.rendered}"

  private_ip = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "30")}"

  tags {
    Name = "logstash-server-a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "logstash_server_b" {
  instance_type = "${var.logstash_instance_type}"

  ami = "${data.aws_ami.logstash.id}"

  subnet_id = "${data.terraform_remote_state.network.network-private-subnet-b-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.logstash_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.logstash_server_profile.name}"

  user_data = "${data.template_file.logstash_server_user_data.rendered}"

  private_ip = "${replace(var.aws_network_private_subnet_cidr_b, "0/24", "30")}"

  tags {
    Name = "logstash-server-b"
    Stream = "${var.stream_tag}"
  }
}
*/

resource "aws_launch_configuration" "logstash_launch_configuration" {
  name_prefix   = "logstash-server"
  instance_type = "${var.logstash_instance_type}"

  image_id = "${data.aws_ami.logstash.id}"

  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.logstash_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.logstash_server_profile.name}"

  user_data = "${data.template_file.logstash_server_user_data.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "logstash_asg" {
  name                      = "logstash-asg"
  max_size                  = 6
  min_size                  = 0
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.logstash_launch_configuration.name}"

  vpc_zone_identifier = [
    "${data.terraform_remote_state.network.network-private-subnet-a-id}",
    "${data.terraform_remote_state.network.network-private-subnet-b-id}",
    "${data.terraform_remote_state.network.network-private-subnet-c-id}"
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
    value               = "logstash-server"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }
}
