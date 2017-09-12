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
# Remote state
##############################################################################

terraform {
  backend "s3" {
    bucket = "nextbreakpoint-terraform-state"
    region = "eu-west-1"
    key = "kibana.tfstate"
  }
}

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
# Kibana servers
##############################################################################

resource "aws_security_group" "kibana_server" {
  name = "kibana-security-group"
  description = "Kibana server security group"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.aws_bastion_vpc_cidr}"]
  }

  ingress {
    from_port = 8300
    to_port = 8302
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 8300
    to_port = 8302
    protocol = "udp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 9200
    to_port = 9400
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 5601
    to_port = 5601
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

data "template_file" "kibana_server_user_data" {
  template = "${file("provision/kibana.tpl")}"

  vars {
    aws_region              = "${var.aws_region}"
    es_cluster              = "${var.es_cluster}"
    es_environment          = "${var.es_environment}"
    security_groups         = "${aws_security_group.kibana_server.id}"
    minimum_master_nodes    = "${var.minimum_master_nodes}"
    availability_zones      = "${var.availability_zones}"
    elasticsearch_data_dir  = "/mnt/elasticsearch/data"
    elasticsearch_logs_dir  = "/mnt/elasticsearch/logs"
    elasticsearch_host      = "_site_"
    elasticsearch_node      = "elasticsearch.${var.hosted_zone_name}"
    consul_log_file         = "${var.consul_log_file}"
    log_group_name          = "${var.log_group_name}"
    log_stream_name         = "${var.log_stream_name}"
  }
}

resource "aws_iam_instance_profile" "kibana_server_profile" {
    name = "kibana-server-profile"
    role = "${aws_iam_role.kibana_server_role.name}"
}

resource "aws_iam_role" "kibana_server_role" {
  name = "kibana-server-role"

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

resource "aws_iam_role_policy" "kibana_server_role_policy" {
  name = "kibana-server-role-policy"
  role = "${aws_iam_role.kibana_server_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:DescribeInstances"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

data "aws_ami" "kibana" {
  most_recent = true

  filter {
    name = "name"
    values = ["kibana-${var.kibana_version}-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["${var.account_id}"]
}

resource "aws_instance" "kibana_server_a" {
  instance_type = "${var.kibana_instance_type}"

  ami = "${data.aws_ami.kibana.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-a-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.kibana_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.kibana_server_profile.name}"

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
    Name = "kibana-server-a"
    Stream = "${var.stream_tag}"
  }

  provisioner "file" {
      source = "provision/filebeat-index.json"
      destination = "/tmp/filebeat-index.json"
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.kibana_server_user_data.rendered}"
  }
}

resource "aws_instance" "kibana_server_b" {
  instance_type = "${var.kibana_instance_type}"

  ami = "${data.aws_ami.kibana.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-b-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.kibana_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.kibana_server_profile.name}"

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
    Name = "kibana-server-b"
    Stream = "${var.stream_tag}"
  }

  provisioner "file" {
      source = "provision/filebeat-index.json"
      destination = "/tmp/filebeat-index.json"
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.kibana_server_user_data.rendered}"
  }
}

##############################################################################
# Load balancer
##############################################################################

resource "aws_security_group" "kibana_elb" {
  name = "kibana-elb-security-group"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port = 5601
    to_port = 5601
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

resource "aws_elb" "kibana" {
  name = "kibana-elb"

  depends_on = ["aws_security_group.kibana_elb"]

  security_groups = ["${aws_security_group.kibana_elb.id}"]

  subnets = [
    "${data.terraform_remote_state.vpc.network-public-subnet-a-id}",
    "${data.terraform_remote_state.vpc.network-public-subnet-b-id}"
  ]

  listener {
    instance_port = 5601
    instance_protocol = "http"
    lb_port = 5601
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 3
    timeout = 10
    target = "TCP:5601"
    interval = 30
  }

  instances = [
    "${aws_instance.kibana_server_a.id}",
    "${aws_instance.kibana_server_b.id}"
  ]

  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400
  internal = false

  tags {
    stream = "${var.stream_tag}"
  }
}

##############################################################################
# Route 53
##############################################################################

resource "aws_route53_record" "kibana" {
  zone_id = "${var.public_hosted_zone_id}"
  name = "kibana.${var.public_hosted_zone_name}"
  type = "A"

  alias {
    name = "${aws_elb.kibana.dns_name}"
    zone_id = "${aws_elb.kibana.zone_id}"
    evaluate_target_health = true
  }
}
