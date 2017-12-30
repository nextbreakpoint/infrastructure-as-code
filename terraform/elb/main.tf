##############################################################################
# Provider
##############################################################################

provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
  version = "~> 0.1"
}

##############################################################################
# ELB
##############################################################################

resource "aws_security_group" "webserver_elb" {
  name = "internal-elb-security-group"
  description = "Internal ELB security group"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

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
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Stream = "${var.stream_tag}"
  }
}

data "aws_acm_certificate" "webserver_elb" {
  domain   = "*.${var.hosted_zone_name}"
  statuses = ["ISSUED"]
}

resource "aws_elb" "webserver_elb" {
  name = "internal-elb"

  security_groups = ["${aws_security_group.webserver_elb.id}"]

  subnets = [
    "${data.terraform_remote_state.network.network-private-subnet-a-id}",
    "${data.terraform_remote_state.network.network-private-subnet-b-id}",
    "${data.terraform_remote_state.network.network-private-subnet-c-id}"
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
    ssl_certificate_id  = "${data.aws_acm_certificate.webserver_elb.arn}"
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
  internal = true

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
  zone_id = "${data.terraform_remote_state.zones.network-hosted-zone-id}"
  name = "consul.${data.terraform_remote_state.zones.network-hosted-zone-name}"
  type = "A"

  alias {
    name = "${aws_elb.webserver_elb.dns_name}"
    zone_id = "${aws_elb.webserver_elb.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "kibana" {
  zone_id = "${data.terraform_remote_state.zones.network-hosted-zone-id}"
  name = "kibana.${data.terraform_remote_state.zones.network-hosted-zone-name}"
  type = "A"

  alias {
    name = "${aws_elb.webserver_elb.dns_name}"
    zone_id = "${aws_elb.webserver_elb.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "jenkins" {
  zone_id = "${data.terraform_remote_state.zones.network-hosted-zone-id}"
  name = "jenkins.${data.terraform_remote_state.zones.network-hosted-zone-name}"
  type = "A"

  alias {
    name = "${aws_elb.webserver_elb.dns_name}"
    zone_id = "${aws_elb.webserver_elb.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "sonarqube" {
  zone_id = "${data.terraform_remote_state.zones.network-hosted-zone-id}"
  name = "sonarqube.${data.terraform_remote_state.zones.network-hosted-zone-name}"
  type = "A"

  alias {
    name = "${aws_elb.webserver_elb.dns_name}"
    zone_id = "${aws_elb.webserver_elb.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "artifactory" {
  zone_id = "${data.terraform_remote_state.zones.network-hosted-zone-id}"
  name = "artifactory.${data.terraform_remote_state.zones.network-hosted-zone-name}"
  type = "A"

  alias {
    name = "${aws_elb.webserver_elb.dns_name}"
    zone_id = "${aws_elb.webserver_elb.zone_id}"
    evaluate_target_health = true
  }
}
