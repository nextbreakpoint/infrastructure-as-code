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
# Backend servers
##############################################################################

resource "aws_security_group" "backend_service" {
  name = "backend service"
  description = "service security group"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 5044
    to_port = 5044
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
    Name = "backend service security group"
    Stream = "${var.stream_tag}"
  }
}

data "template_file" "backend_service_user_data" {
  template = "${file("provision/service.tpl")}"

  vars {
    aws_region              = "${var.aws_region}"
    environment             = "${var.environment}"
    security_groups         = "${aws_security_group.backend_service.id}"
    consul_log_file         = "${var.consul_log_file}"
    log_group_name          = "${var.log_group_name}"
    log_stream_name         = "${var.log_stream_name}"
  }
}

resource "aws_iam_instance_profile" "backend_service_profile" {
    name = "service_profile"
    roles = ["${var.service_profile}"]
}

resource "aws_instance" "backend_service_a" {
  instance_type = "t2.small"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.base_amis, var.aws_region)}"

  subnet_id = "${data.terraform_remote_state.network.network-private-subnet-a-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.backend_service.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.backend_service_profile.id}"

  connection {
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
    bastion_user = "ec2-user"
    bastion_host = "bastion.${var.public_hosted_zone_name}"
  }

  tags {
    Name = "backend_service_a"
    Stream = "${var.stream_tag}"
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.backend_service_user_data.rendered}"
  }
}

resource "aws_instance" "backend_service_b" {
  instance_type = "t2.small"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.base_amis, var.aws_region)}"

  subnet_id = "${data.terraform_remote_state.network.network-private-subnet-b-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.backend_service.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.backend_service_profile.id}"

  connection {
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
    bastion_user = "ec2-user"
    bastion_host = "bastion.${var.public_hosted_zone_name}"
  }

  tags {
    Name = "backend_service_b"
    Stream = "${var.stream_tag}"
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.backend_service_user_data.rendered}"
  }
}
