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

##############################################################################
# ELB
##############################################################################

resource "aws_security_group" "webserver_elb" {
  name = "webserver-elb-security-group"
  description = "ELB security group"
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

  subnets = [
    "${data.terraform_remote_state.vpc.network-public-subnet-a-id}",
    "${data.terraform_remote_state.vpc.network-public-subnet-b-id}",
    "${data.terraform_remote_state.vpc.network-public-subnet-c-id}"
  ]

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
  autoscaling_group_name = "${data.terraform_remote_state.webserver.webserver-asg-id}"
  elb = "${aws_elb.webserver_elb.id}"
}

resource "aws_autoscaling_attachment" "webserver_asg_b" {
  autoscaling_group_name = "${data.terraform_remote_state.webserver.webserver-asg-id}"
  elb = "${aws_elb.webserver_elb.id}"
}

##############################################################################
# Route 53
##############################################################################

resource "aws_route53_record" "consul" {
  zone_id = "${data.terraform_remote_state.vpc.hosted-zone-id}"
  name = "consul.${var.hosted_zone_name}"
  type = "A"

  alias {
    name = "${aws_elb.webserver_elb.dns_name}"
    zone_id = "${aws_elb.webserver_elb.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "kibana" {
  zone_id = "${data.terraform_remote_state.vpc.hosted-zone-id}"
  name = "kibana.${var.hosted_zone_name}"
  type = "A"

  alias {
    name = "${aws_elb.webserver_elb.dns_name}"
    zone_id = "${aws_elb.webserver_elb.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "jenkins" {
  zone_id = "${data.terraform_remote_state.vpc.hosted-zone-id}"
  name = "jenkins.${var.hosted_zone_name}"
  type = "A"

  alias {
    name = "${aws_elb.webserver_elb.dns_name}"
    zone_id = "${aws_elb.webserver_elb.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "sonarqube" {
  zone_id = "${data.terraform_remote_state.vpc.hosted-zone-id}"
  name = "sonarqube.${var.hosted_zone_name}"
  type = "A"

  alias {
    name = "${aws_elb.webserver_elb.dns_name}"
    zone_id = "${aws_elb.webserver_elb.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "artifactory" {
  zone_id = "${data.terraform_remote_state.vpc.hosted-zone-id}"
  name = "artifactory.${var.hosted_zone_name}"
  type = "A"

  alias {
    name = "${aws_elb.webserver_elb.dns_name}"
    zone_id = "${aws_elb.webserver_elb.zone_id}"
    evaluate_target_health = true
  }
}
