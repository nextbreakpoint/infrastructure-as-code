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
# Puppet server
##############################################################################

resource "aws_security_group" "puppet_server" {
  name = "pupper server"
  description = "puppet server security group"
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

data "template_file" "puppet_server_user_data" {
  template = "${file("provision/puppet.tpl")}"

  vars {
    aws_region              = "${var.aws_region}"
    environment             = "${var.environment}"
    security_groups         = "${aws_security_group.puppet_server.id}"
    consul_log_file         = "${var.consul_log_file}"
    log_group_name          = "${var.log_group_name}"
    log_stream_name         = "${var.log_stream_name}"
    logstash_host           = "logstash.${data.terraform_remote_state.vpc.hosted-zone-name}"
  }
}

resource "aws_iam_instance_profile" "puppet_server_profile" {
    name = "puppet_server_profile"
    roles = ["${var.service_profile}"]
}

resource "aws_instance" "puppet_server" {
  instance_type = "t2.small"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.puppet_amis, var.aws_region)}"

  subnet_id = "${data.terraform_remote_state.network.network-public-subnet-a-id}"
  associate_public_ip_address = "true"
  security_groups = ["${aws_security_group.puppet_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.puppet_server_profile.id}"

  connection {
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
  }

  tags {
    Name = "puppet_server"
    Stream = "${var.stream_tag}"
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.puppet_server_user_data.rendered}"
  }
}

##############################################################################
# Route 53
##############################################################################

resource "aws_route53_record" "puppet" {
  zone_id = "${data.terraform_remote_state.vpc.hosted-zone-id}"
  name = "puppet.${data.terraform_remote_state.vpc.hosted-zone-name}"
  type = "A"

  alias {
    name = "${aws_instance.puppet_server.dns_name}"
    zone_id = "${aws_instance.puppet_server.zone_id}"
    evaluate_target_health = true
  }
}

