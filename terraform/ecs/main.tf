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
# ECS
##############################################################################

resource "aws_security_group" "ecs_server" {
  name = "ecs-server-security-group"
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

resource "aws_iam_instance_profile" "ecs_server_profile" {
    name = "ecs-server-profile"
    role = "${aws_iam_role.ecs_server_role.name}"
}

resource "aws_iam_role" "ecs_server_role" {
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

resource "aws_iam_role_policy" "ecs_server_role_policy" {
  name = "ecs-server-role-policy"
  role = "${aws_iam_role.ecs_server_role.id}"

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

resource "aws_ecs_cluster" "services" {
  name = "services"
}

data "template_file" "ecs_launch_user_data" {
  template = "${file("provision/cluster.tpl")}"

  vars {
    environment             = "${var.environment}"
    bucket_name             = "${var.secrets_bucket_name}"
    cluster_name            = "${aws_ecs_cluster.services.name}"
    consul_secret           = "${var.consul_secret}"
    consul_datacenter       = "${var.consul_datacenter}"
    consul_hostname         = "${var.consul_record}.${var.hosted_zone_name}"
    consul_log_file         = "${var.consul_log_file}"
    logstash_host           = "logstash.${var.hosted_zone_name}"
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
resource "aws_instance" "ecs_server_a" {
  depends_on = ["aws_ecs_cluster.services"]
  instance_type = "${var.ecs_instance_type}"

  ami = "${data.aws_ami.ecs_cluster.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-a-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.ecs_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.ecs_server_profile.name}"

  user_data = "${data.template_file.ecs_launch_user_data.rendered}"

  tags {
    Name = "ecs-server-a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "ecs_server_b" {
  depends_on = ["aws_ecs_cluster.services"]
  instance_type = "${var.ecs_instance_type}"

  ami = "${data.aws_ami.ecs_cluster.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-b-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.ecs_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.ecs_server_profile.name}"

  user_data = "${data.template_file.ecs_launch_user_data.rendered}"

  tags {
    Name = "ecs-server-b"
    Stream = "${var.stream_tag}"
  }
}
*/

resource "aws_launch_configuration" "ecs_launch_configuration" {
  depends_on = ["aws_ecs_cluster.services"]
  name_prefix   = "ecs-server-"
  instance_type = "${var.cluster_instance_type}"

  image_id = "${data.aws_ami.ecs_cluster.id}"

  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.ecs_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.ecs_server_profile.name}"

  user_data = "${data.template_file.ecs_launch_user_data.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ecs_asg_a" {
  depends_on = ["aws_ecs_cluster.services"]
  name                      = "ecs-cluster-asg-a"
  max_size                  = 4
  min_size                  = 0
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.ecs_launch_configuration.name}"

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
    value               = "ecs-server-a"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }
}

resource "aws_autoscaling_group" "ecs_asg_b" {
  depends_on = ["aws_ecs_cluster.services"]
  name                      = "ecs-cluster-asg-b"
  max_size                  = 4
  min_size                  = 0
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.ecs_launch_configuration.name}"

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
    value               = "ecs-server-b"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }
}

/*
resource "aws_security_group" "ecs_elb" {
  name = "ecs-server-elb-security-group"
  description = "ECS Cluster ELB security group"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
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
    Stream = "${var.stream_tag}"
  }
}

resource "aws_iam_server_certificate" "ecs_elb" {
  name_prefix      = "ecs-server-elb-certificate"
  certificate_body = "${file("${var.ecs_elb_certificate_path}")}"
  private_key      = "${file("${var.ecs_elb_private_key_path}")}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elb" "ecs_elb" {
  name               = "server-elb"

  security_groups = ["${aws_security_group.ecs_elb.id}"]

  subnets = [
    "${data.terraform_remote_state.vpc.network-public-subnet-a-id}",
    "${data.terraform_remote_state.vpc.network-public-subnet-b-id}"
  ]

  listener {
    instance_port       = 443
    instance_protocol   = "HTTPS"
    lb_port             = 443
    lb_protocol         = "HTTPS"
    ssl_certificate_id  = "${aws_iam_server_certificate.ecs_elb.arn}"
  }

  listener {
    instance_port       = 80
    instance_protocol   = "HTTP"
    lb_port             = 80
    lb_protocol         = "HTTP"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 60
    target              = "HTTPS:443/"
    interval            = 300
  }

  cross_zone_load_balancing   = false
  idle_timeout                = 400
  connection_draining         = false
  connection_draining_timeout = 400

  tags {
    Stream = "${var.stream_tag}"
  }
}

resource "aws_autoscaling_attachment" "ecs_asg_a" {
  autoscaling_group_name = "${aws_autoscaling_group.ecs_asg_a.id}"
  elb = "${aws_elb.ecs_elb.id}"
}

resource "aws_autoscaling_attachment" "ecs_asg_b" {
  autoscaling_group_name = "${aws_autoscaling_group.ecs_asg_b.id}"
  elb = "${aws_elb.ecs_elb.id}"
}

resource "aws_elb_attachment" "ecs_server_a" {
  elb      = "${aws_elb.ecs_elb.id}"
  instance = "${aws_instance.ecs_server_a.id}"
}

resource "aws_elb_attachment" "ecs_server_b" {
  elb      = "${aws_elb.ecs_elb.id}"
  instance = "${aws_instance.ecs_server_b.id}"
}

##############################################################################
# Route 53
##############################################################################

resource "aws_route53_record" "ecs_elb" {
  zone_id = "${var.public_hosted_zone_id}"
  name = "cluster.${var.public_hosted_zone_name}"
  type = "A"

  alias {
    name = "${aws_elb.ecs_elb.dns_name}"
    zone_id = "${aws_elb.ecs_elb.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "ecs_dns" {
  zone_id = "${data.terraform_remote_state.vpc.hosted-zone-id}"
  name = "cluster.${var.hosted_zone_name}"
  type = "CNAME"
  ttl = "30"

  records = ["${aws_elb.ecs_elb.dns_name}"]
}
*/
