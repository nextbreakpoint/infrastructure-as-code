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

##############################################################################
# ECS
##############################################################################

resource "aws_security_group" "cluster_server" {
  name = "ecs-cluster-security-group"
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

resource "aws_iam_instance_profile" "cluster_server_profile" {
    name = "ecs-server-profile"
    role = "${aws_iam_role.cluster_server_role.name}"
}

resource "aws_iam_role" "cluster_server_role" {
  name = "cluster-server-role"

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

resource "aws_iam_role_policy" "cluster_server_role_policy" {
  name = "ecs-cluster-server-role-policy"
  role = "${aws_iam_role.cluster_server_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecs:CreateCluster",
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:Submit*",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_ecs_cluster" "services" {
  name = "services"
}

data "template_file" "cluster_launch_user_data" {
  template = "${file("provision/cluster.sh")}"

  vars {
    cluster_name = "${aws_ecs_cluster.services.name}"
  }
}

data "aws_ami" "ecs_cluster" {
  most_recent = true

  filter {
    name = "name"
    values = ["amzn-ami-2017.03.f-amazon-ecs-optimized"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

/*
resource "aws_instance" "cluster_server_a" {
  depends_on = ["aws_ecs_cluster.services"]
  instance_type = "${var.cluster_instance_type}"

  ami = "${data.aws_ami.ecs_cluster.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-a-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.cluster_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.cluster_server_profile.name}"

  user_data = "${data.template_file.cluster_launch_user_data.rendered}"

  tags {
    Name = "cluster-server-a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "cluster_server_b" {
  depends_on = ["aws_ecs_cluster.services"]
  instance_type = "${var.cluster_instance_type}"

  ami = "${data.aws_ami.ecs_cluster.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-b-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.cluster_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.cluster_server_profile.name}"

  user_data = "${data.template_file.cluster_launch_user_data.rendered}"

  tags {
    Name = "cluster-server-b"
    Stream = "${var.stream_tag}"
  }
}
*/

resource "aws_launch_configuration" "cluster_launch_configuration" {
  depends_on = ["aws_ecs_cluster.services"]
  name_prefix   = "cluster-"
  instance_type = "${var.cluster_instance_type}"

  image_id = "${data.aws_ami.ecs_cluster.id}"

  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.cluster_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.cluster_server_profile.name}"

  user_data = "${data.template_file.cluster_launch_user_data.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "cluster_asg_a" {
  depends_on = ["aws_ecs_cluster.services"]
  name                      = "cluster-asg-a"
  max_size                  = 4
  min_size                  = 0
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.cluster_launch_configuration.name}"

  vpc_zone_identifier = [
    "${data.terraform_remote_state.vpc.network-private-subnet-a-id}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "stream"
    value               = "${var.stream_tag}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "cluster-server-a"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }
}

resource "aws_autoscaling_group" "cluster_asg_b" {
  depends_on = ["aws_ecs_cluster.services"]
  name                      = "cluster-asg-b"
  max_size                  = 4
  min_size                  = 0
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.cluster_launch_configuration.name}"

  vpc_zone_identifier = [
    "${data.terraform_remote_state.vpc.network-private-subnet-b-id}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "stream"
    value               = "${var.stream_tag}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "cluster-server-b"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }
}

resource "aws_security_group" "cluster_elb" {
  name = "ecs-cluster-elb-security-group"
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
    stream = "${var.stream_tag}"
  }
}

resource "aws_iam_server_certificate" "cluster_elb" {
  name_prefix      = "ecs-cluster-elb-certificate"
  certificate_body = "${file("${var.ecs_cluster_elb_certificate_path}")}"
  private_key      = "${file("${var.ecs_cluster_elb_private_key_path}")}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elb" "cluster_elb" {
  name               = "cluster-elb"

  security_groups = ["${aws_security_group.cluster_elb.id}"]

  subnets = [
    "${data.terraform_remote_state.vpc.network-public-subnet-a-id}",
    "${data.terraform_remote_state.vpc.network-public-subnet-b-id}"
  ]

  listener {
    instance_port       = 443
    instance_protocol   = "HTTPS"
    lb_port             = 443
    lb_protocol         = "HTTPS"
    ssl_certificate_id  = "${aws_iam_server_certificate.cluster_elb.arn}"
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
    stream = "${var.stream_tag}"
  }
}

resource "aws_autoscaling_attachment" "cluster_asg_a" {
  autoscaling_group_name = "${aws_autoscaling_group.cluster_asg_a.id}"
  elb = "${aws_elb.cluster_elb.id}"
}

resource "aws_autoscaling_attachment" "cluster_asg_b" {
  autoscaling_group_name = "${aws_autoscaling_group.cluster_asg_b.id}"
  elb = "${aws_elb.cluster_elb.id}"
}

/*
resource "aws_elb_attachment" "cluster_server_a" {
  elb      = "${aws_elb.cluster_elb.id}"
  instance = "${aws_instance.cluster_server_a.id}"
}

resource "aws_elb_attachment" "cluster_server_b" {
  elb      = "${aws_elb.cluster_elb.id}"
  instance = "${aws_instance.cluster_server_b.id}"
}
*/

##############################################################################
# Route 53
##############################################################################

resource "aws_route53_record" "cluster_elb" {
  zone_id = "${var.public_hosted_zone_id}"
  name = "cluster.${var.public_hosted_zone_name}"
  type = "A"

  alias {
    name = "${aws_elb.cluster_elb.dns_name}"
    zone_id = "${aws_elb.cluster_elb.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "cluster_dns" {
  zone_id = "${data.terraform_remote_state.vpc.hosted-zone-id}"
  name = "cluster.${var.hosted_zone_name}"
  type = "CNAME"
  ttl = "30"

  records = ["${aws_elb.cluster_elb.dns_name}"]
}

##############################################################################
# S3 Bucket
##############################################################################

resource "aws_s3_bucket" "services" {
  bucket = "${var.services_bucket_name}"
  region = "${var.aws_region}"
  versioning = {
    enabled = true
  }
  acl = "private"
  force_destroy  = true

  tags {
    stream = "${var.stream_tag}"
  }
}

/*
data "aws_vpc_endpoint" "s3" {
  vpc_id       = "${aws_vpc.vpc.id}"
  service_name = "com.amazonaws.eu-east-1.s3"
}

data "aws_iam_policy_document" "services" {
  statement {
    sid = "Access-to-specific-VPC-only"

    effect = "Deny"

    principals = {
      type = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.services.id}/*",
    ]

    condition {
      test     = "StringNotEquals"
      variable = "aws:sourceVpce"

      values = [
        "${aws_vpc_endpoint.s3.id}"
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "services_policy" {
  bucket = "${aws_s3_bucket.services.id}"
  policy = "${data.aws_iam_policy_document.services.json}"
}
*/
