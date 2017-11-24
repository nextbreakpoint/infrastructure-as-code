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
# Elasticsearch servers
##############################################################################

resource "aws_security_group" "elasticsearch_server" {
  name = "elasticsearch-security-group"
  description = "Elasticsearch security group"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.aws_bastion_vpc_cidr}"]
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

data "template_file" "elasticsearch_server_user_data" {
  template = "${file("provision/elasticsearch.tpl")}"

  vars {
    aws_region              = "${var.aws_region}"
    environment             = "${var.environment}"
    bucket_name             = "${var.secrets_bucket_name}"
    consul_secret           = "${var.consul_secret}"
    consul_datacenter       = "${var.consul_datacenter}"
    consul_hostname         = "${var.consul_record}.${var.hosted_zone_name}"
    consul_log_file         = "${var.consul_log_file}"
    security_groups         = "${aws_security_group.elasticsearch_server.id}"
    minimum_master_nodes    = "${var.minimum_master_nodes}"
    volume_name             = "${var.volume_name}"
    hosted_zone_name        = "${var.hosted_zone_name}"
    public_hosted_zone_name = "${var.public_hosted_zone_name}"
    logstash_host           = "logstash.${var.hosted_zone_name}"
    cluster_name            = "${var.elasticsearch_cluster_name}"
    filebeat_version        = "${var.filebeat_version}"
    elasticsearch_version   = "${var.elasticsearch_version}"
    elasticsearch_nodes     = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "10")},${replace(var.aws_network_private_subnet_cidr_b, "0/24", "10")}"
    kibana_password         = "${var.kibana_password}"
    logstash_password       = "${var.logstash_password}"
    elasticsearch_password  = "${var.elasticsearch_password}"
  }
}

resource "aws_iam_instance_profile" "elasticsearch_server_profile" {
    name = "elasticsearch-server-profile"
    role = "${aws_iam_role.elasticsearch_server_role.name}"
}

resource "aws_iam_role" "elasticsearch_server_role" {
  name = "elasticsearch-server-role"

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

resource "aws_iam_role_policy" "elasticsearch_server_role_policy" {
  name = "elasticsearch-server-role-policy"
  role = "${aws_iam_role.elasticsearch_server_role.id}"

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
    name = "name"
    values = ["base-${var.base_version}-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["${var.account_id}"]
}

resource "aws_instance" "elasticsearch_server_a" {
  instance_type = "${var.elasticsearch_instance_type}"

  ami = "${data.aws_ami.elasticsearch.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-a-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.elasticsearch_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.elasticsearch_server_profile.name}"

  user_data = "${data.template_file.elasticsearch_server_user_data.rendered}"

  private_ip = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "10")}"

  ebs_block_device {
    device_name = "${var.volume_name}"
    volume_size = "${var.volume_size}"
    volume_type = "gp2"
    encrypted = "${var.volume_encrypted}"
    delete_on_termination = true
  }

  tags {
    Name = "elasticsearch-server-a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "elasticsearch_server_b" {
  instance_type = "${var.elasticsearch_instance_type}"

  ami = "${data.aws_ami.elasticsearch.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-b-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.elasticsearch_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.elasticsearch_server_profile.name}"

  user_data = "${data.template_file.elasticsearch_server_user_data.rendered}"

  private_ip = "${replace(var.aws_network_private_subnet_cidr_b, "0/24", "10")}"

  ebs_block_device {
    device_name = "${var.volume_name}"
    volume_size = "${var.volume_size}"
    volume_type = "gp2"
    encrypted = "${var.volume_encrypted}"
    delete_on_termination = true
  }

  tags {
    Name = "elasticsearch-server-b"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_launch_configuration" "elasticsearch_launch_configuration" {
  name_prefix   = "elasticsearch-server-"
  instance_type = "${var.elasticsearch_instance_type}"

  image_id = "${data.aws_ami.elasticsearch.id}"

  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.elasticsearch_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.elasticsearch_server_profile.name}"

  user_data = "${data.template_file.elasticsearch_server_user_data.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "elasticsearch_asg_a" {
  name                      = "elasticsearch-asg-a"
  max_size                  = 4
  min_size                  = 0
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 0
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.elasticsearch_launch_configuration.name}"

  vpc_zone_identifier = [
    "${data.terraform_remote_state.vpc.network-private-subnet-a-id}"
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
    value               = "elasticsearch-server-a"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }
}

resource "aws_autoscaling_group" "elasticsearch_asg_b" {
  name                      = "elasticsearch-asg-b"
  max_size                  = 4
  min_size                  = 0
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 0
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.elasticsearch_launch_configuration.name}"

  vpc_zone_identifier = [
    "${data.terraform_remote_state.vpc.network-private-subnet-b-id}"
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
    value               = "elasticsearch-server-b"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }
}

##############################################################################
# Route 53
##############################################################################

resource "aws_route53_record" "elasticsearch" {
   zone_id = "${data.terraform_remote_state.vpc.hosted-zone-id}"
   name = "elasticsearch.${var.hosted_zone_name}"
   type = "A"
   ttl = "300"

   records = [
     "${aws_instance.elasticsearch_server_a.private_ip}",
     "${aws_instance.elasticsearch_server_b.private_ip}"
   ]
}
