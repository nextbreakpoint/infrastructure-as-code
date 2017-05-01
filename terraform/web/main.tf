##############################################################################
# Provider
##############################################################################

provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
  shared_credentials_file = "${var.aws_shared_credentials_file}"
}

##############################################################################
# Remote state
##############################################################################

data "terraform_remote_state" "vpc" {
    backend = "s3"
    config {
        bucket = "nextbreakpoint-terraform-state"
        region = "${var.aws_region}"
        key = "vpc.tfstate"
    }
}

data "terraform_remote_state" "network" {
    backend = "s3"
    config {
        bucket = "nextbreakpoint-terraform-state"
        region = "${var.aws_region}"
        key = "network.tfstate"
    }
}

##############################################################################
# Web servers
##############################################################################

resource "aws_security_group" "web_server" {
  name = "web server"
  description = "web server security group"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.network-vpc-cidr}"]
  }

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "udp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.network-vpc-cidr}"]
  }

  egress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.network-vpc-cidr}"]
  }

  egress {
    from_port = 0
    to_port = 65535
    protocol = "udp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.network-vpc-cidr}"]
  }

  tags {
    Name = "web server security group"
    Stream = "${var.stream_tag}"
  }
}

data "template_file" "web_server_user_data_a" {
  template = "${file("provision/nginx.tpl")}"

  vars {
    aws_region              = "${var.aws_region}"
    environment             = "${var.environment}"
    security_groups         = "${aws_security_group.web_server.id}"
    consul_log_file         = "${var.consul_log_file}"
    log_group_name          = "${var.log_group_name}"
    log_stream_name         = "${var.log_stream_name}"
    logstash_host           = "logstash.${var.hosted_zone_name}"
    kibana_host             = "kibana.${var.hosted_zone_name}"
    consul_host             = "consul.${var.hosted_zone_name}"
    jenkins_host            = "jenkins.${var.hosted_zone_name}"
    sonarqube_host          = "sonarqube.${var.hosted_zone_name}"
    artifactory_host        = "artifactory.${var.hosted_zone_name}"
  }
}

data "template_file" "web_server_user_data_b" {
  template = "${file("provision/nginx.tpl")}"

  vars {
    aws_region              = "${var.aws_region}"
    environment             = "${var.environment}"
    security_groups         = "${aws_security_group.web_server.id}"
    consul_log_file         = "${var.consul_log_file}"
    log_group_name          = "${var.log_group_name}"
    log_stream_name         = "${var.log_stream_name}"
    logstash_host           = "logstash.${var.hosted_zone_name}"
    kibana_host             = "kibana.${var.hosted_zone_name}"
    consul_host             = "consul.${var.hosted_zone_name}"
    jenkins_host            = "jenkins.${var.hosted_zone_name}"
    sonarqube_host          = "sonarqube.${var.hosted_zone_name}"
    artifactory_host        = "artifactory.${var.hosted_zone_name}"
  }
}

resource "aws_iam_instance_profile" "web_server_profile" {
    name = "web_server_profile"
    roles = ["${var.web_server_profile}"]
}

resource "aws_instance" "web_server_a" {
  instance_type = "t2.small"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.nginx_amis, var.aws_region)}"

  subnet_id = "${data.terraform_remote_state.network.network-public-subnet-a-id}"
  associate_public_ip_address = "true"
  security_groups = ["${aws_security_group.web_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.web_server_profile.id}"

  connection {
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
  }

  tags {
    Name = "web_server_a"
    Stream = "${var.stream_tag}"
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.web_server_user_data_a.rendered}"
  }
}

resource "aws_instance" "web_server_b" {
  instance_type = "t2.small"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.nginx_amis, var.aws_region)}"

  subnet_id = "${data.terraform_remote_state.network.network-public-subnet-b-id}"
  associate_public_ip_address = "true"
  security_groups = ["${aws_security_group.web_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.web_server_profile.id}"

  connection {
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
  }

  tags {
    Name = "web_server_b"
    Stream = "${var.stream_tag}"
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.web_server_user_data_b.rendered}"
  }
}

##############################################################################
# Load balancer
##############################################################################

resource "aws_security_group" "web_elb" {
  name = "web elb"
  description = "Web load balacer"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 80
    to_port = 80
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
    Name = "web elb security group"
    stream = "${var.stream_tag}"
  }
}

resource "aws_elb" "web" {
  name = "web-elb"
  security_groups = ["${aws_security_group.web_elb.id}"]
  subnets = ["${data.terraform_remote_state.network.network-public-subnet-a-id}","${data.terraform_remote_state.network.network-public-subnet-b-id}"]

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 3
    timeout = 10
    target = "TCP:80"
    interval = 30
  }

  instances = ["${aws_instance.web_server_a.id}", "${aws_instance.web_server_b.id}"]
  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400
  internal = false

  tags {
    Name = "web elb"
    stream = "${var.stream_tag}"
  }
}

##############################################################################
# Route 53
##############################################################################

resource "aws_route53_record" "consul" {
  zone_id = "${var.public_hosted_zone_id}"
  name = "consul.${var.public_hosted_zone_name}"
  type = "A"

  alias {
    name = "${aws_elb.web.dns_name}"
    zone_id = "${aws_elb.web.zone_id}"
    evaluate_target_health = true
  }
}

/*resource "aws_route53_record" "kibana" {
  zone_id = "${var.public_hosted_zone_id}"
  name = "kibana.${var.public_hosted_zone_name}"
  type = "A"

  alias {
    name = "${aws_elb.web.dns_name}"
    zone_id = "${aws_elb.web.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "jenkins" {
  zone_id = "${var.public_hosted_zone_id}"
  name = "jenkins.${var.public_hosted_zone_name}"
  type = "A"

  alias {
    name = "${aws_elb.web.dns_name}"
    zone_id = "${aws_elb.web.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "sonarqube" {
  zone_id = "${var.public_hosted_zone_id}"
  name = "sonarqube.${var.public_hosted_zone_name}"
  type = "A"

  alias {
    name = "${aws_elb.web.dns_name}"
    zone_id = "${aws_elb.web.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "artifactory" {
  zone_id = "${var.public_hosted_zone_id}"
  name = "artifactory.${var.public_hosted_zone_name}"
  type = "A"

  alias {
    name = "${aws_elb.web.dns_name}"
    zone_id = "${aws_elb.web.zone_id}"
    evaluate_target_health = true
  }
}*/
