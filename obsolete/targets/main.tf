##############################################################################
# Providers
##############################################################################

provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
  version = "~> 1.0"
}

##############################################################################
# Resources
##############################################################################

resource "aws_alb_target_group" "manager_8080" {
  name     = "${var.environment}-${var.colour}-manager-8080"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = "${data.terraform_remote_state.vpc.network-vpc-id}"

  health_check {
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    matcher             = "200,301,302"
  }
}

resource "aws_alb_target_group" "manager_8081" {
  name     = "${var.environment}-${var.colour}-manager-8081"
  port     = 8081
  protocol = "HTTP"
  vpc_id   = "${data.terraform_remote_state.vpc.network-vpc-id}"

  health_check {
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    matcher             = "200,301,302"
  }
}

resource "aws_alb_target_group" "manager_9000" {
  name     = "${var.environment}-${var.colour}-manager-9000"
  port     = 9000
  protocol = "HTTP"
  vpc_id   = "${data.terraform_remote_state.vpc.network-vpc-id}"

  health_check {
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    matcher             = "200,301,302"
  }
}

resource "aws_alb_target_group" "manager_2080" {
  name     = "${var.environment}-${var.colour}-manager-2080"
  port     = 2080
  protocol = "HTTP"
  vpc_id   = "${data.terraform_remote_state.vpc.network-vpc-id}"

  health_check {
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    matcher             = "200,301,302"
  }
}

resource "aws_alb_target_group" "manager_3000" {
  name     = "${var.environment}-${var.colour}-manager-3000"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = "${data.terraform_remote_state.vpc.network-vpc-id}"

  health_check {
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    matcher             = "200,301,302"
  }
}

resource "aws_alb_target_group" "manager_5601" {
  name     = "${var.environment}-${var.colour}-manager-5601"
  port     = 5601
  protocol = "HTTPS"
  vpc_id   = "${data.terraform_remote_state.vpc.network-vpc-id}"

  health_check {
    protocol            = "HTTPS"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    matcher             = "200,301,302"
  }
}

resource "aws_alb_target_group" "worker_public_80" {
  name     = "${var.environment}-${var.colour}-worker-public-80"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${data.terraform_remote_state.vpc.network-vpc-id}"

  health_check {
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    matcher             = "200,301,302"
  }
}

resource "aws_alb_target_group" "worker_public_443" {
  name     = "${var.environment}-${var.colour}-worker-public-443"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = "${data.terraform_remote_state.vpc.network-vpc-id}"

  health_check {
    protocol            = "HTTPS"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    matcher             = "200,301,302"
  }
}

resource "aws_alb_target_group" "worker_8500" {
  name     = "${var.environment}-${var.colour}-worker-8500"
  port     = 8500
  protocol = "HTTPS"
  vpc_id   = "${data.terraform_remote_state.vpc.network-vpc-id}"

  health_check {
    protocol            = "HTTPS"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    matcher             = "200,301,302"
  }
}

resource aws_lb_target_group_attachment "manager_a_8080" {
  target_group_arn = "${aws_alb_target_group.manager_8080.arn}"
  target_id        = "${data.terraform_remote_state.swarm.swarm-manager-a-id}"
  port             = "8080"
}

resource aws_lb_target_group_attachment "manager_b_8080" {
  target_group_arn = "${aws_alb_target_group.manager_8080.arn}"
  target_id        = "${data.terraform_remote_state.swarm.swarm-manager-b-id}"
  port             = "8080"
}

resource aws_lb_target_group_attachment "manager_c_8080" {
  target_group_arn = "${aws_alb_target_group.manager_8080.arn}"
  target_id        = "${data.terraform_remote_state.swarm.swarm-manager-c-id}"
  port             = "8080"
}

resource aws_lb_target_group_attachment "manager_a_8081" {
  target_group_arn = "${aws_alb_target_group.manager_8081.arn}"
  target_id        = "${data.terraform_remote_state.swarm.swarm-manager-a-id}"
  port             = "8081"
}

resource aws_lb_target_group_attachment "manager_b_8081" {
  target_group_arn = "${aws_alb_target_group.manager_8081.arn}"
  target_id        = "${data.terraform_remote_state.swarm.swarm-manager-b-id}"
  port             = "8081"
}

resource aws_lb_target_group_attachment "manager_c_8081" {
  target_group_arn = "${aws_alb_target_group.manager_8081.arn}"
  target_id        = "${data.terraform_remote_state.swarm.swarm-manager-c-id}"
  port             = "8081"
}

resource aws_lb_target_group_attachment "manager_a_9000" {
  target_group_arn = "${aws_alb_target_group.manager_9000.arn}"
  target_id        = "${data.terraform_remote_state.swarm.swarm-manager-a-id}"
  port             = "9000"
}

resource aws_lb_target_group_attachment "manager_b_9000" {
  target_group_arn = "${aws_alb_target_group.manager_9000.arn}"
  target_id        = "${data.terraform_remote_state.swarm.swarm-manager-b-id}"
  port             = "9000"
}

resource aws_lb_target_group_attachment "manager_c_9000" {
  target_group_arn = "${aws_alb_target_group.manager_9000.arn}"
  target_id        = "${data.terraform_remote_state.swarm.swarm-manager-c-id}"
  port             = "9000"
}

resource aws_lb_target_group_attachment "manager_a_2080" {
  target_group_arn = "${aws_alb_target_group.manager_2080.arn}"
  target_id        = "${data.terraform_remote_state.swarm.swarm-manager-a-id}"
  port             = "2080"
}

resource aws_lb_target_group_attachment "manager_b_2080" {
  target_group_arn = "${aws_alb_target_group.manager_2080.arn}"
  target_id        = "${data.terraform_remote_state.swarm.swarm-manager-b-id}"
  port             = "2080"
}

resource aws_lb_target_group_attachment "manager_c_2080" {
  target_group_arn = "${aws_alb_target_group.manager_2080.arn}"
  target_id        = "${data.terraform_remote_state.swarm.swarm-manager-c-id}"
  port             = "2080"
}

resource aws_lb_target_group_attachment "manager_a_3000" {
  target_group_arn = "${aws_alb_target_group.manager_3000.arn}"
  target_id        = "${data.terraform_remote_state.swarm.swarm-manager-a-id}"
  port             = "3000"
}

resource aws_lb_target_group_attachment "manager_b_3000" {
  target_group_arn = "${aws_alb_target_group.manager_3000.arn}"
  target_id        = "${data.terraform_remote_state.swarm.swarm-manager-b-id}"
  port             = "3000"
}

resource aws_lb_target_group_attachment "manager_c_3000" {
  target_group_arn = "${aws_alb_target_group.manager_3000.arn}"
  target_id        = "${data.terraform_remote_state.swarm.swarm-manager-c-id}"
  port             = "3000"
}

resource aws_lb_target_group_attachment "manager_a_5601" {
  target_group_arn = "${aws_alb_target_group.manager_5601.arn}"
  target_id        = "${data.terraform_remote_state.swarm.swarm-manager-a-id}"
  port             = "5601"
}

resource aws_lb_target_group_attachment "manager_b_5601" {
  target_group_arn = "${aws_alb_target_group.manager_5601.arn}"
  target_id        = "${data.terraform_remote_state.swarm.swarm-manager-b-id}"
  port             = "5601"
}

resource aws_lb_target_group_attachment "manager_c_5601" {
  target_group_arn = "${aws_alb_target_group.manager_5601.arn}"
  target_id        = "${data.terraform_remote_state.swarm.swarm-manager-c-id}"
  port             = "5601"
}

resource aws_lb_target_group_attachment "worker_public_a_80" {
  target_group_arn = "${aws_alb_target_group.worker_public_80.arn}"
  target_id        = "${data.terraform_remote_state.swarm.swarm-worker-a-id}"
  port             = "80"
}

resource aws_lb_target_group_attachment "worker_public_b_80" {
  target_group_arn = "${aws_alb_target_group.worker_public_80.arn}"
  target_id        = "${data.terraform_remote_state.swarm.swarm-worker-b-id}"
  port             = "80"
}

resource aws_lb_target_group_attachment "worker_public_c_80" {
  target_group_arn = "${aws_alb_target_group.worker_public_80.arn}"
  target_id        = "${data.terraform_remote_state.swarm.swarm-worker-c-id}"
  port             = "80"
}

resource aws_lb_target_group_attachment "worker_public_a_443" {
  target_group_arn = "${aws_alb_target_group.worker_public_443.arn}"
  target_id        = "${data.terraform_remote_state.swarm.swarm-worker-a-id}"
  port             = "443"
}

resource aws_lb_target_group_attachment "worker_public_b_443" {
  target_group_arn = "${aws_alb_target_group.worker_public_443.arn}"
  target_id        = "${data.terraform_remote_state.swarm.swarm-worker-b-id}"
  port             = "443"
}

resource aws_lb_target_group_attachment "worker_public_c_443" {
  target_group_arn = "${aws_alb_target_group.worker_public_443.arn}"
  target_id        = "${data.terraform_remote_state.swarm.swarm-worker-c-id}"
  port             = "443"
}

resource aws_lb_target_group_attachment "worker_a_8500" {
  target_group_arn = "${aws_alb_target_group.worker_8500.arn}"
  target_id        = "${data.terraform_remote_state.swarm.swarm-worker-a-id}"
  port             = "8500"
}

resource aws_lb_target_group_attachment "worker_b_8500" {
  target_group_arn = "${aws_alb_target_group.worker_8500.arn}"
  target_id        = "${data.terraform_remote_state.swarm.swarm-worker-b-id}"
  port             = "8500"
}

resource aws_lb_target_group_attachment "worker_c_8500" {
  target_group_arn = "${aws_alb_target_group.worker_8500.arn}"
  target_id        = "${data.terraform_remote_state.swarm.swarm-worker-c-id}"
  port             = "8500"
}

# resource "aws_autoscaling_attachment" "webserver_https" {
#   autoscaling_group_name = "${aws_autoscaling_group.webserver.id}"
#   alb_target_group_arn   = "${aws_alb_target_group.webserver_https.arn}"
# }

resource "aws_alb_listener_rule" "manager_8080" {
  listener_arn = "${data.terraform_remote_state.lb.lb-internal-listener-https-arn}"
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.manager_8080.arn}"
  }

  condition {
    field  = "host-header"
    values = ["${var.environment}-${var.colour}-jenkins.${var.hosted_zone_name}"]
  }
}

resource "aws_alb_listener_rule" "manager_8081" {
  listener_arn = "${data.terraform_remote_state.lb.lb-internal-listener-https-arn}"
  priority     = 110

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.manager_8081.arn}"
  }

  condition {
    field  = "host-header"
    values = ["${var.environment}-${var.colour}-artifactory.${var.hosted_zone_name}"]
  }
}

resource "aws_alb_listener_rule" "manager_9000" {
  listener_arn = "${data.terraform_remote_state.lb.lb-internal-listener-https-arn}"
  priority     = 120

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.manager_9000.arn}"
  }

  condition {
    field  = "host-header"
    values = ["${var.environment}-${var.colour}-sonarqube.${var.hosted_zone_name}"]
  }
}

resource "aws_alb_listener_rule" "manager_2080" {
  listener_arn = "${data.terraform_remote_state.lb.lb-internal-listener-https-arn}"
  priority     = 130

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.manager_2080.arn}"
  }

  condition {
    field  = "host-header"
    values = ["${var.environment}-${var.colour}-graphite.${var.hosted_zone_name}"]
  }
}

resource "aws_alb_listener_rule" "manager_3000" {
  listener_arn = "${data.terraform_remote_state.lb.lb-internal-listener-https-arn}"
  priority     = 140

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.manager_3000.arn}"
  }

  condition {
    field  = "host-header"
    values = ["${var.environment}-${var.colour}-grafana.${var.hosted_zone_name}"]
  }
}

resource "aws_alb_listener_rule" "manager_5601" {
  listener_arn = "${data.terraform_remote_state.lb.lb-internal-listener-https-arn}"
  priority     = 150

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.manager_5601.arn}"
  }

  condition {
    field  = "host-header"
    values = ["${var.environment}-${var.colour}-kibana.${var.hosted_zone_name}"]
  }
}

resource "aws_alb_listener_rule" "worker_public_80" {
  listener_arn = "${data.terraform_remote_state.lb.lb-public-listener-http-arn}"
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.worker_public_80.arn}"
  }

  condition {
    field  = "host-header"
    values = ["${var.environment}-${var.colour}-nginx.${var.hosted_zone_name}"]
  }
}

resource "aws_alb_listener_rule" "worker_public_443" {
  listener_arn = "${data.terraform_remote_state.lb.lb-public-listener-https-arn}"
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.worker_public_443.arn}"
  }

  condition {
    field  = "host-header"
    values = ["${var.environment}-${var.colour}-nginx.${var.hosted_zone_name}"]
  }
}

resource "aws_alb_listener_rule" "worker_8500" {
  listener_arn = "${data.terraform_remote_state.lb.lb-internal-listener-https-arn}"
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.worker_8500.arn}"
  }

  condition {
    field  = "host-header"
    values = ["${var.environment}-${var.colour}-consul.${var.hosted_zone_name}"]
  }
}

resource "aws_route53_record" "jenkins" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-jenkins.${var.hosted_zone_name}"
  type    = "A"

  alias {
    name                   = "${data.terraform_remote_state.lb.lb-internal-alb-dns-name}"
    zone_id                = "${data.terraform_remote_state.lb.lb-internal-alb-zone-id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "artifactory" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-artifactory.${var.hosted_zone_name}"
  type    = "A"

  alias {
    name                   = "${data.terraform_remote_state.lb.lb-internal-alb-dns-name}"
    zone_id                = "${data.terraform_remote_state.lb.lb-internal-alb-zone-id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "sonarqube" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-sonarqube.${var.hosted_zone_name}"
  type    = "A"

  alias {
    name                   = "${data.terraform_remote_state.lb.lb-internal-alb-dns-name}"
    zone_id                = "${data.terraform_remote_state.lb.lb-internal-alb-zone-id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "graphite" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-graphite.${var.hosted_zone_name}"
  type    = "A"

  alias {
    name                   = "${data.terraform_remote_state.lb.lb-internal-alb-dns-name}"
    zone_id                = "${data.terraform_remote_state.lb.lb-internal-alb-zone-id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "grafana" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-grafana.${var.hosted_zone_name}"
  type    = "A"

  alias {
    name                   = "${data.terraform_remote_state.lb.lb-internal-alb-dns-name}"
    zone_id                = "${data.terraform_remote_state.lb.lb-internal-alb-zone-id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "kibana" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-kibana.${var.hosted_zone_name}"
  type    = "A"

  alias {
    name                   = "${data.terraform_remote_state.lb.lb-internal-alb-dns-name}"
    zone_id                = "${data.terraform_remote_state.lb.lb-internal-alb-zone-id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "nginx" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-nginx.${var.hosted_zone_name}"
  type    = "A"

  alias {
    name                   = "${data.terraform_remote_state.lb.lb-public-alb-dns-name}"
    zone_id                = "${data.terraform_remote_state.lb.lb-public-alb-zone-id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "consul" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-consul.${var.hosted_zone_name}"
  type    = "A"

  alias {
    name                   = "${data.terraform_remote_state.lb.lb-internal-alb-dns-name}"
    zone_id                = "${data.terraform_remote_state.lb.lb-internal-alb-zone-id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "zookeeper-a" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-zookeeper-a.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${data.terraform_remote_state.swarm.swarm-worker-a-private-ip}"
  ]
}

resource "aws_route53_record" "zookeeper-b" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-zookeeper-b.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${data.terraform_remote_state.swarm.swarm-worker-b-private-ip}"
  ]
}

resource "aws_route53_record" "zookeeper-c" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-zookeeper-c.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${data.terraform_remote_state.swarm.swarm-worker-c-private-ip}"
  ]
}

resource "aws_route53_record" "kafka-a" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-kafka-a.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${data.terraform_remote_state.swarm.swarm-worker-a-private-ip}"
  ]
}

resource "aws_route53_record" "kafka-b" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-kafka-b.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${data.terraform_remote_state.swarm.swarm-worker-b-private-ip}"
  ]
}

resource "aws_route53_record" "kafka-c" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-kafka-c.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${data.terraform_remote_state.swarm.swarm-worker-c-private-ip}"
  ]
}

resource "aws_route53_record" "elasticsearch-a" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-elasticsearch-a.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${data.terraform_remote_state.swarm.swarm-worker-a-private-ip}"
  ]
}

resource "aws_route53_record" "elasticsearch-b" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-elasticsearch-b.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${data.terraform_remote_state.swarm.swarm-worker-b-private-ip}"
  ]
}

resource "aws_route53_record" "elasticsearch-c" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-elasticsearch-c.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${data.terraform_remote_state.swarm.swarm-worker-c-private-ip}"
  ]
}

resource "aws_route53_record" "logstash-a" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-logstash-a.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${data.terraform_remote_state.swarm.swarm-worker-a-private-ip}"
  ]
}

resource "aws_route53_record" "logstash-b" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-logstash-b.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${data.terraform_remote_state.swarm.swarm-worker-b-private-ip}"
  ]
}

resource "aws_route53_record" "logstash-c" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-logstash-c.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${data.terraform_remote_state.swarm.swarm-worker-c-private-ip}"
  ]
}

resource "aws_route53_record" "consul-a" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-consul-a.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${data.terraform_remote_state.swarm.swarm-worker-a-private-ip}"
  ]
}

resource "aws_route53_record" "consul-b" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-consul-b.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${data.terraform_remote_state.swarm.swarm-worker-b-private-ip}"
  ]
}

resource "aws_route53_record" "consul-c" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-consul-c.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${data.terraform_remote_state.swarm.swarm-worker-c-private-ip}"
  ]
}

resource "aws_route53_record" "cassandra-a" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-cassandra-a.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${data.terraform_remote_state.swarm.swarm-worker-a-private-ip}"
  ]
}

resource "aws_route53_record" "cassandra-b" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-cassandra-b.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${data.terraform_remote_state.swarm.swarm-worker-b-private-ip}"
  ]
}

resource "aws_route53_record" "cassandra-c" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-cassandra-c.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${data.terraform_remote_state.swarm.swarm-worker-c-private-ip}"
  ]
}
