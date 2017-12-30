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
# ECS
##############################################################################

resource "aws_security_group" "ecs_node" {
  name = "ecs-security-group"
  description = "ECS security group"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.aws_bastion_vpc_cidr}"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 3000
    to_port = 3099
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 8080
    to_port = 8080
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

resource "aws_iam_instance_profile" "ecs_node_profile" {
    name = "ecs-server-profile"
    role = "${aws_iam_role.ecs_node_role.name}"
}

resource "aws_iam_role" "ecs_node_role" {
  name = "ecs-server-role"

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

resource "aws_iam_role_policy" "ecs_node_role_policy" {
  name = "ecs-server-policy"
  role = "${aws_iam_role.ecs_node_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*",
        "ecs:CreateCluster",
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:Submit*",
        "ecs:DescribeContainerInstances",
        "ecs:ListContainerInstances",
        "ecs:ListTasks",
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

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs-cluster"
}

data "template_file" "ecs_launch_user_data" {
  template = "${file("provision/cluster.tpl")}"

  vars {
    environment             = "${var.environment}"
    bucket_name             = "${var.secrets_bucket_name}"
    cluster_name            = "${aws_ecs_cluster.ecs_cluster.name}"
    consul_secret           = "${var.consul_secret}"
    consul_datacenter       = "${var.consul_datacenter}"
    consul_nodes            = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "90")},${replace(var.aws_network_private_subnet_cidr_b, "0/24", "90")},${replace(var.aws_network_private_subnet_cidr_c, "0/24", "90")}"
    consul_logfile          = "${var.consul_logfile}"
    filebeat_version        = "${var.filebeat_version}"
  }
}

data "aws_ami" "ecs_cluster" {
  most_recent = true

  filter {
    name = "name"
    values = ["ecs-${var.base_version}-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

/*
resource "aws_instance" "ecs_node_a" {
  depends_on = ["aws_ecs_cluster.ecs_cluster"]
  instance_type = "${var.ecs_instance_type}"

  ami = "${data.aws_ami.ecs_cluster.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-a-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.ecs_node.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.ecs_node_profile.name}"

  user_data = "${data.template_file.ecs_launch_user_data.rendered}"

  tags {
    Name = "ecs-server-a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "ecs_node_b" {
  depends_on = ["aws_ecs_cluster.ecs_cluster"]
  instance_type = "${var.ecs_instance_type}"

  ami = "${data.aws_ami.ecs_cluster.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-b-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.ecs_node.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.ecs_node_profile.name}"

  user_data = "${data.template_file.ecs_launch_user_data.rendered}"

  tags {
    Name = "ecs-server-b"
    Stream = "${var.stream_tag}"
  }
}
*/

resource "aws_launch_configuration" "ecs_launch_configuration" {
  depends_on = ["aws_ecs_cluster.ecs_cluster"]
  name_prefix   = "ecs-server-"
  instance_type = "${var.cluster_instance_type}"

  image_id = "${data.aws_ami.ecs_cluster.id}"

  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.ecs_node.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.ecs_node_profile.name}"

  user_data = "${data.template_file.ecs_launch_user_data.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ecs_asg" {
  depends_on = ["aws_ecs_cluster.ecs_cluster"]
  name                      = "ecs-asg"
  max_size                  = 6
  min_size                  = 0
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.ecs_launch_configuration.name}"

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
    value               = "ecs-server"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }
}
