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

resource "aws_security_group" "kubernetes_server" {
  name = "kubernetes-server-security-group"
  description = "Kubernetes security group"
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

resource "aws_iam_instance_profile" "kubernetes_server_profile" {
    name = "kubernetes-server-profile"
    role = "${aws_iam_role.kubernetes_server_role.name}"
}

resource "aws_iam_role" "kubernetes_server_role" {
  name = "kubernetes-server-role"

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

resource "aws_iam_role_policy" "kubernetes_server_role_policy" {
  name = "kubernetes-server-role-policy"
  role = "${aws_iam_role.kubernetes_server_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*",
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

data "template_file" "kubernetes_launch_user_data_master_a" {
  template = "${file("provision/kubernetes-master.tpl")}"

  vars {
    aws_region              = "${var.aws_region}"
    environment             = "${var.environment}"
    bucket_name             = "${var.secrets_bucket_name}"
    security_groups         = "${aws_security_group.kubernetes_server.id}"
    consul_secret           = "${var.consul_secret}"
    consul_datacenter       = "${var.consul_datacenter}"
    consul_hostname         = "${var.consul_record}.${var.hosted_zone_name}"
    consul_log_file         = "${var.consul_log_file}"
    hosted_zone_name        = "${var.hosted_zone_name}"
    public_hosted_zone_name = "${var.public_hosted_zone_name}"
    logstash_host           = "logstash.${var.hosted_zone_name}"
    filebeat_version        = "${var.filebeat_version}"
    kubernetes_token        = "${var.kubernetes_token}"
    pod_network_cidr        = "${var.kubernetes_pod_network_cidr}"
  }
}

data "template_file" "kubernetes_launch_user_data_master_b" {
  template = "${file("provision/kubernetes-master.tpl")}"

  vars {
    aws_region              = "${var.aws_region}"
    environment             = "${var.environment}"
    bucket_name             = "${var.secrets_bucket_name}"
    security_groups         = "${aws_security_group.kubernetes_server.id}"
    consul_datacenter       = "${var.consul_datacenter}"
    consul_secret           = "${var.consul_secret}"
    consul_hostname         = "${var.consul_record}.${var.hosted_zone_name}"
    consul_log_file         = "${var.consul_log_file}"
    hosted_zone_name        = "${var.hosted_zone_name}"
    public_hosted_zone_name = "${var.public_hosted_zone_name}"
    logstash_host           = "logstash.${var.hosted_zone_name}"
    filebeat_version        = "${var.filebeat_version}"
    kubernetes_token        = "${var.kubernetes_token}"
    pod_network_cidr        = "${var.kubernetes_pod_network_cidr}"
  }
}

data "template_file" "kubernetes_launch_user_data_node_a" {
  template = "${file("provision/kubernetes-node.tpl")}"

  vars {
    aws_region              = "${var.aws_region}"
    environment             = "${var.environment}"
    bucket_name             = "${var.secrets_bucket_name}"
    security_groups         = "${aws_security_group.kubernetes_server.id}"
    consul_secret           = "${var.consul_secret}"
    consul_datacenter       = "${var.consul_datacenter}"
    consul_hostname         = "${var.consul_record}.${var.hosted_zone_name}"
    consul_log_file         = "${var.consul_log_file}"
    hosted_zone_name        = "${var.hosted_zone_name}"
    public_hosted_zone_name = "${var.public_hosted_zone_name}"
    logstash_host           = "logstash.${var.hosted_zone_name}"
    filebeat_version        = "${var.filebeat_version}"
    kubernetes_master_ip    = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "200")}"
    kubernetes_master_port  = "6443"
    kubernetes_token        = "${var.kubernetes_token}"
  }
}

data "template_file" "kubernetes_launch_user_data_node_b" {
  template = "${file("provision/kubernetes-node.tpl")}"

  vars {
    aws_region              = "${var.aws_region}"
    environment             = "${var.environment}"
    bucket_name             = "${var.secrets_bucket_name}"
    security_groups         = "${aws_security_group.kubernetes_server.id}"
    consul_secret           = "${var.consul_secret}"
    consul_datacenter       = "${var.consul_datacenter}"
    consul_hostname         = "${var.consul_record}.${var.hosted_zone_name}"
    consul_log_file         = "${var.consul_log_file}"
    hosted_zone_name        = "${var.hosted_zone_name}"
    public_hosted_zone_name = "${var.public_hosted_zone_name}"
    logstash_host           = "logstash.${var.hosted_zone_name}"
    filebeat_version        = "${var.filebeat_version}"
    kubernetes_master_ip    = "${replace(var.aws_network_private_subnet_cidr_b, "0/24", "200")}"
    kubernetes_master_port  = "6443"
    kubernetes_token        = "${var.kubernetes_token}"
  }
}

data "aws_ami" "kubernetes_server" {
  most_recent = true

  filter {
    name = "name"
    values = ["kubernetes-${var.kubernetes_version}-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "kubernetes_server_a" {
  instance_type = "${var.kubernetes_instance_type}"

  ami = "${data.aws_ami.kubernetes_server.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-a-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.kubernetes_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.kubernetes_server_profile.name}"

  user_data = "${data.template_file.kubernetes_launch_user_data_master_a.rendered}"

  private_ip = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "200")}"

  tags {
    Name = "kubernetes-master-a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_launch_configuration" "kubernetes_launch_configuration_a" {
  name_prefix   = "kubernetes-"
  instance_type = "${var.kubernetes_instance_type}"

  image_id = "${data.aws_ami.kubernetes_server.id}"

  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.kubernetes_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.kubernetes_server_profile.name}"

  user_data = "${data.template_file.kubernetes_launch_user_data_node_a.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "kubernetes_asg_a" {
  name                      = "kubernetes-asg-a"
  max_size                  = 4
  min_size                  = 0
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.kubernetes_launch_configuration_a.name}"

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
    value               = "kubernetes-node-a"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }
}

/*
resource "aws_instance" "kubernetes_server_b" {
  instance_type = "${var.kubernetes_instance_type}"

  ami = "${data.aws_ami.kubernetes_server.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-b-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.kubernetes_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.kubernetes_server_profile.name}"

  user_data = "${data.template_file.kubernetes_launch_user_data_master_b.rendered}"

  private_ip = "${replace(var.aws_network_private_subnet_cidr_b, "0/24", "200")}"

  tags {
    Name = "kubernetes-master-b"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_launch_configuration" "kubernetes_launch_configuration_b" {
  name_prefix   = "kubernetes-"
  instance_type = "${var.kubernetes_instance_type}"

  image_id = "${data.aws_ami.kubernetes_server.id}"

  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.kubernetes_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.kubernetes_server_profile.name}"

  user_data = "${data.template_file.kubernetes_launch_user_data_node_b.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "kubernetes_asg_b" {
  name                      = "kubernetes-asg-b"
  max_size                  = 4
  min_size                  = 0
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.kubernetes_launch_configuration_b.name}"

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
    value               = "kubernetes-node-b"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }
}
*/

resource "aws_security_group" "kubernetes_elb" {
  name = "kubernetes-elb-security-group"
  description = "Kubernetes ELB security group"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port = 6443
    to_port = 6443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8001
    to_port = 8001
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

resource "aws_iam_server_certificate" "kubernetes_elb" {
  name_prefix      = "kubernetes-elb-certificate"
  certificate_body = "${file("${var.kubernetes_elb_certificate_path}")}"
  private_key      = "${file("${var.kubernetes_elb_private_key_path}")}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elb" "kubernetes_elb" {
  name               = "kubernetes-server-elb"

  security_groups = ["${aws_security_group.kubernetes_elb.id}"]

  subnets = [
    "${data.terraform_remote_state.vpc.network-public-subnet-a-id}",
    "${data.terraform_remote_state.vpc.network-public-subnet-b-id}"
  ]

  listener {
    instance_port       = 6443
    instance_protocol   = "HTTPS"
    lb_port             = 6443
    lb_protocol         = "HTTPS"
    ssl_certificate_id  = "${aws_iam_server_certificate.kubernetes_elb.arn}"
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = false
  connection_draining_timeout = 400

  tags {
    Stream = "${var.stream_tag}"
  }
}

resource "aws_autoscaling_attachment" "kubernetes_asg_a" {
  autoscaling_group_name = "${aws_autoscaling_group.kubernetes_asg_a.id}"
  elb = "${aws_elb.kubernetes_elb.id}"
}

resource "aws_elb_attachment" "kubernetes_server_a" {
  elb      = "${aws_elb.kubernetes_elb.id}"
  instance = "${aws_instance.kubernetes_server_a.id}"
}

/*
resource "aws_autoscaling_attachment" "kubernetes_asg_b" {
  autoscaling_group_name = "${aws_autoscaling_group.kubernetes_asg_b.id}"
  elb = "${aws_elb.kubernetes_elb.id}"
}

resource "aws_elb_attachment" "kubernetes_server_b" {
  elb      = "${aws_elb.kubernetes_elb.id}"
  instance = "${aws_instance.kubernetes_server_b.id}"
}
*/

##############################################################################
# Route 53
##############################################################################

resource "aws_route53_record" "kubernetes_elb" {
  zone_id = "${var.public_hosted_zone_id}"
  name = "kubernetes.${var.public_hosted_zone_name}"
  type = "A"

  alias {
    name = "${aws_elb.kubernetes_elb.dns_name}"
    zone_id = "${aws_elb.kubernetes_elb.zone_id}"
    evaluate_target_health = true
  }
}
