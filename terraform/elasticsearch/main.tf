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

resource "aws_security_group" "elasticsearch" {
  name        = "elasticsearch"
  description = "Elasticsearch security group"
  vpc_id      = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port   = 22
    to_port     = 22
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
    from_port   = 9200
    to_port     = 9400
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

data "template_file" "elasticsearch" {
  template = "${file("provision/elasticsearch.tpl")}"

  vars {
    aws_region             = "${var.aws_region}"
    environment            = "${var.environment}"
    bucket_name            = "${var.secrets_bucket_name}"
    consul_secret          = "${var.consul_secret}"
    consul_datacenter      = "${var.consul_datacenter}"
    consul_nodes           = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "90")},${replace(var.aws_network_private_subnet_cidr_b, "0/24", "90")},${replace(var.aws_network_private_subnet_cidr_c, "0/24", "90")}"
    security_groups        = "${aws_security_group.elasticsearch.id}"
    minimum_master_nodes   = "${var.minimum_master_nodes}"
    volume_name            = "${var.volume_name}"
    cluster_name           = "${var.elasticsearch_cluster_name}"
    filebeat_version       = "${var.filebeat_version}"
    elasticsearch_version  = "${var.elasticsearch_version}"
    elasticsearch_nodes    = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "10")},${replace(var.aws_network_private_subnet_cidr_b, "0/24", "10")}"
    kibana_password        = "${var.kibana_password}"
    logstash_password      = "${var.logstash_password}"
    elasticsearch_password = "${var.elasticsearch_password}"
    hosted_zone_dns        = "${replace(var.aws_network_vpc_cidr, "0/16", "2")}"
  }
}

resource "aws_iam_instance_profile" "elasticsearch" {
  name = "elasticsearch"
  role = "${aws_iam_role.elasticsearch.name}"
}

resource "aws_iam_role" "elasticsearch" {
  name = "elasticsearch"

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

resource "aws_iam_role_policy" "elasticsearch" {
  name = "elasticsearch"
  role = "${aws_iam_role.elasticsearch.id}"

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

data "aws_ami" "elasticsearch" {
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

resource "aws_instance" "elasticsearch_a" {
  ami                         = "${data.aws_ami.elasticsearch.id}"
  instance_type               = "${var.elasticsearch_instance_type}"
  subnet_id                   = "${data.terraform_remote_state.network.network-private-subnet-a-id}"
  private_ip                  = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "10")}"
  vpc_security_group_ids      = ["${aws_security_group.elasticsearch.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.elasticsearch.name}"
  user_data                   = "${data.template_file.elasticsearch.rendered}"
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
    Name   = "elasticsearch-a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "elasticsearch_b" {
  ami                         = "${data.aws_ami.elasticsearch.id}"
  instance_type               = "${var.elasticsearch_instance_type}"
  subnet_id                   = "${data.terraform_remote_state.network.network-private-subnet-b-id}"
  private_ip                  = "${replace(var.aws_network_private_subnet_cidr_b, "0/24", "10")}"
  vpc_security_group_ids      = ["${aws_security_group.elasticsearch.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.elasticsearch.name}"
  user_data                   = "${data.template_file.elasticsearch.rendered}"
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
    Name   = "elasticsearch-b"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_launch_configuration" "elasticsearch" {
  name_prefix                 = "elasticsearch-"
  image_id                    = "${data.aws_ami.elasticsearch.id}"
  instance_type               = "${var.elasticsearch_instance_type}"
  security_groups             = ["${aws_security_group.elasticsearch.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.elasticsearch.name}"
  user_data                   = "${data.template_file.elasticsearch.rendered}"
  key_name                    = "${var.key_name}"
  associate_public_ip_address = "false"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "elasticsearch" {
  name                      = "elasticsearch"
  max_size                  = 6
  min_size                  = 0
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 0
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.elasticsearch.name}"

  vpc_zone_identifier = [
    "${data.terraform_remote_state.network.network-private-subnet-a-id}",
    "${data.terraform_remote_state.network.network-private-subnet-b-id}",
    "${data.terraform_remote_state.network.network-private-subnet-c-id}",
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
    value               = "elasticsearch"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }
}
