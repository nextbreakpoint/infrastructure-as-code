##############################################################################
# Providers
##############################################################################

provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
  version = "~> 0.1"
}

##############################################################################
# Resources
##############################################################################

resource "aws_security_group" "lb_internal" {
  name        = "${var.environment}-${var.colour}-lb-int"
  description = "Internal ALB security group"
  vpc_id      = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}", "${var.aws_openvpn_vpc_cidr}"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}", "${var.aws_openvpn_vpc_cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  tags {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
  }
}

data "aws_acm_certificate" "lb_internal" {
  domain   = "*.internal.${var.hosted_zone_name}"
  statuses = ["ISSUED"]
}

resource "aws_alb" "lb_internal" {
  name = "${var.environment}-${var.colour}-lb-int"

  security_groups = ["${aws_security_group.lb_internal.id}"]

  subnets = [
    "${data.terraform_remote_state.network.network-private-subnet-a-id}",
    "${data.terraform_remote_state.network.network-private-subnet-b-id}",
    "${data.terraform_remote_state.network.network-private-subnet-c-id}",
  ]

  internal = true

  tags {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
  }
}

resource "aws_alb_target_group" "lb_internal_http" {
  name     = "${var.environment}-${var.colour}-lb-int-http"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${data.terraform_remote_state.vpc.network-vpc-id}"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    matcher             = "200,301,400,404"
  }
}

resource "aws_alb_target_group" "lb_internal_https" {
  name     = "${var.environment}-${var.colour}-lb-int-https"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = "${data.terraform_remote_state.vpc.network-vpc-id}"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    matcher             = "200,301,400,404"
  }
}

resource "aws_alb_listener" "lb_internal_http" {
  load_balancer_arn = "${aws_alb.lb_internal.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.lb_internal_http.arn}"
    type             = "forward"
  }
}

resource "aws_alb_listener" "lb_internal_https" {
  load_balancer_arn = "${aws_alb.lb_internal.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  certificate_arn   = "${data.aws_acm_certificate.lb_internal.arn}"

  default_action {
    target_group_arn = "${aws_alb_target_group.lb_internal_https.arn}"
    type             = "forward"
  }
}

resource "aws_security_group" "lb_public" {
  name        = "${var.environment}-${var.colour}-lb-pub"
  description = "Public ALB security group"
  vpc_id      = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  tags {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
  }
}

data "aws_acm_certificate" "lb_public" {
  domain   = "*.${var.hosted_zone_name}"
  statuses = ["ISSUED"]
}

resource "aws_alb" "lb_public" {
  name = "${var.environment}-${var.colour}-lb-pub"

  security_groups = ["${aws_security_group.lb_public.id}"]

  subnets = [
    "${data.terraform_remote_state.network.network-public-subnet-a-id}",
    "${data.terraform_remote_state.network.network-public-subnet-b-id}",
    "${data.terraform_remote_state.network.network-public-subnet-c-id}",
  ]

  internal = false

  tags {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
  }
}

resource "aws_alb_target_group" "lb_public_http" {
  name     = "${var.environment}-${var.colour}-lb-pub-http"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${data.terraform_remote_state.vpc.network-vpc-id}"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    matcher             = "200,301,400,404"
  }
}

resource "aws_alb_target_group" "lb_public_https" {
  name     = "${var.environment}-${var.colour}-lb-pub-https"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = "${data.terraform_remote_state.vpc.network-vpc-id}"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    matcher             = "200,301,400,404"
  }
}

resource "aws_alb_listener" "lb_public_http" {
  load_balancer_arn = "${aws_alb.lb_public.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.lb_public_http.arn}"
    type             = "forward"
  }
}

resource "aws_alb_listener" "lb_public_https" {
  load_balancer_arn = "${aws_alb.lb_public.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  certificate_arn   = "${data.aws_acm_certificate.lb_public.arn}"

  default_action {
    target_group_arn = "${aws_alb_target_group.lb_public_https.arn}"
    type             = "forward"
  }
}
