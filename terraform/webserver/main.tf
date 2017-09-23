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
# Web servers
##############################################################################

resource "aws_security_group" "webserver" {
  name = "webserver-security-group"
  description = "NGINX server security group"
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

data "template_file" "webserver_user_data_a" {
  template = "${file("provision/nginx.tpl")}"

  vars {
    aws_region              = "${var.aws_region}"
    environment             = "${var.environment}"
    bucket_name             = "${var.secrets_bucket_name}"
    security_groups         = "${aws_security_group.webserver.id}"
    consul_log_file         = "${var.consul_log_file}"
    log_group_name          = "${var.log_group_name}"
    log_stream_name         = "${var.log_stream_name}"
    hosted_zone_name        = "${var.hosted_zone_name}"
    public_hosted_zone_name = "${var.public_hosted_zone_name}"
    logstash_host           = "logstash.${var.hosted_zone_name}"
  }
}

data "template_file" "webserver_user_data_b" {
  template = "${file("provision/nginx.tpl")}"

  vars {
    aws_region              = "${var.aws_region}"
    environment             = "${var.environment}"
    bucket_name             = "${var.secrets_bucket_name}"
    security_groups         = "${aws_security_group.webserver.id}"
    consul_log_file         = "${var.consul_log_file}"
    log_group_name          = "${var.log_group_name}"
    log_stream_name         = "${var.log_stream_name}"
    hosted_zone_name        = "${var.hosted_zone_name}"
    public_hosted_zone_name = "${var.public_hosted_zone_name}"
    logstash_host           = "logstash.${var.hosted_zone_name}"
  }
}

resource "aws_iam_instance_profile" "webserver_profile" {
    name = "webserver-profile"
    role = "${aws_iam_role.webserver_role.name}"
}

resource "aws_iam_role" "webserver_role" {
  name = "webserver-role"

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

resource "aws_iam_role_policy" "webserver_role_policy" {
  name = "webserver-role-policy"
  role = "${aws_iam_role.webserver_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
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

data "aws_ami" "webserver" {
  most_recent = true

  filter {
    name = "name"
    values = ["nginx-${var.base_version}-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["${var.account_id}"]
}

/*
resource "aws_instance" "webserver_a" {
  instance_type = "${var.web_instance_type}"

  ami = "${data.aws_ami.webserver.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-a-id}"
  associate_public_ip_address = "true"
  security_groups = ["${aws_security_group.webserver.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.webserver_profile.id}"

  tags {
    Name = "webserver-a"
    Stream = "${var.stream_tag}"
  }

  connection {
    host = "${element(aws_instance.webserver_a.*.private_ip, 0)}"
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
    bastion_user = "ec2-user"
    bastion_host = "bastion.${var.public_hosted_zone_name}"
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.webserver_user_data_a.rendered}"
  }
}

resource "aws_instance" "webserver_b" {
  instance_type = "${var.web_instance_type}"

  ami = "${data.aws_ami.webserver.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-b-id}"
  associate_public_ip_address = "true"
  security_groups = ["${aws_security_group.webserver.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.webserver_profile.id}"

  tags {
    Name = "webserver-b"
    Stream = "${var.stream_tag}"
  }

  connection {
    host = "${element(aws_instance.webserver_b.*.private_ip, 0)}"
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
    bastion_user = "ec2-user"
    bastion_host = "bastion.${var.public_hosted_zone_name}"
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.webserver_user_data_b.rendered}"
  }
}
*/

resource "aws_launch_configuration" "webserver_launch_configuration_a" {
  name_prefix   = "webserver-"
  instance_type = "${var.web_instance_type}"

  image_id = "${data.aws_ami.webserver.id}"

  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.webserver.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.webserver_profile.name}"

  user_data = "${data.template_file.webserver_user_data_a.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "webserver_launch_configuration_b" {
  name_prefix   = "webserver-"
  instance_type = "${var.web_instance_type}"

  image_id = "${data.aws_ami.webserver.id}"

  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.webserver.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.webserver_profile.name}"

  user_data = "${data.template_file.webserver_user_data_b.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "webserver_asg_a" {
  name                      = "webserver-asg-a"
  max_size                  = 4
  min_size                  = 0
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.webserver_launch_configuration_a.name}"

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
    value               = "webserver-a"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }
}

resource "aws_autoscaling_group" "webserver_asg_b" {
  name                      = "webserver-asg-b"
  max_size                  = 4
  min_size                  = 0
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.webserver_launch_configuration_b.name}"

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
    value               = "webserver-b"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }
}

resource "aws_security_group" "webserver_elb" {
  name = "webserver-elb-security-group"
  description = "NGINX load balacer security group"
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

resource "aws_iam_server_certificate" "webserver_elb" {
  name_prefix      = "webserver-elb-certificate"
  certificate_body = "${file("${var.webserver_elb_certificate_path}")}"
  private_key      = "${file("${var.webserver_elb_private_key_path}")}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elb" "webserver_elb" {
  name = "webserver-elb"
  security_groups = ["${aws_security_group.webserver_elb.id}"]
  subnets = ["${data.terraform_remote_state.vpc.network-public-subnet-a-id}","${data.terraform_remote_state.vpc.network-public-subnet-b-id}"]

  listener {
    instance_port = 80
    instance_protocol = "HTTP"
    lb_port = 80
    lb_protocol = "HTTP"
  }

  listener {
    instance_port       = 443
    instance_protocol   = "HTTPS"
    lb_port             = 443
    lb_protocol         = "HTTPS"
    ssl_certificate_id  = "${aws_iam_server_certificate.webserver_elb.arn}"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 3
    timeout = 10
    target = "TCP:80"
    interval = 30
  }

  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400
  internal = false

  tags {
    Stream = "${var.stream_tag}"
  }
}

resource "aws_autoscaling_attachment" "webserver_asg_a" {
  autoscaling_group_name = "${aws_autoscaling_group.webserver_asg_a.id}"
  elb = "${aws_elb.webserver_elb.id}"
}

resource "aws_autoscaling_attachment" "webserver_asg_b" {
  autoscaling_group_name = "${aws_autoscaling_group.webserver_asg_b.id}"
  elb = "${aws_elb.webserver_elb.id}"
}

##############################################################################
# Route 53
##############################################################################

resource "aws_route53_record" "consul" {
  zone_id = "${var.public_hosted_zone_id}"
  name = "consul.${var.public_hosted_zone_name}"
  type = "A"

  alias {
    name = "${aws_elb.webserver_elb.dns_name}"
    zone_id = "${aws_elb.webserver_elb.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "kibana" {
  zone_id = "${var.public_hosted_zone_id}"
  name = "kibana.${var.public_hosted_zone_name}"
  type = "A"

  alias {
    name = "${aws_elb.webserver_elb.dns_name}"
    zone_id = "${aws_elb.webserver_elb.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "jenkins" {
  zone_id = "${var.public_hosted_zone_id}"
  name = "jenkins.${var.public_hosted_zone_name}"
  type = "A"

  alias {
    name = "${aws_elb.webserver_elb.dns_name}"
    zone_id = "${aws_elb.webserver_elb.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "sonarqube" {
  zone_id = "${var.public_hosted_zone_id}"
  name = "sonarqube.${var.public_hosted_zone_name}"
  type = "A"

  alias {
    name = "${aws_elb.webserver_elb.dns_name}"
    zone_id = "${aws_elb.webserver_elb.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "artifactory" {
  zone_id = "${var.public_hosted_zone_id}"
  name = "artifactory.${var.public_hosted_zone_name}"
  type = "A"

  alias {
    name = "${aws_elb.webserver_elb.dns_name}"
    zone_id = "${aws_elb.webserver_elb.zone_id}"
    evaluate_target_health = true
  }
}
