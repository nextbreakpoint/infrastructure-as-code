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
    key = "elasticsearch.tfstate"
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

data "terraform_remote_state" "volumes" {
    backend = "s3"
    config {
        bucket = "nextbreakpoint-terraform-state"
        region = "${var.aws_region}"
        key = "volumes.tfstate"
    }
}

##############################################################################
# Elasticsearch servers
##############################################################################

resource "aws_security_group" "elasticsearch_server" {
  name = "elasticsearch-security-group"
  description = "Elasticsearch security group"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

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

  ingress {
    from_port = 9200
    to_port = 9400
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

data "template_file" "elasticsearch_server_user_data" {
  template = "${file("provision/elasticsearch.tpl")}"

  vars {
    aws_region              = "${var.aws_region}"
    es_cluster              = "${var.es_cluster}"
    es_environment          = "${var.es_environment}"
    security_groups         = "${aws_security_group.elasticsearch_server.id}"
    minimum_master_nodes    = "${var.minimum_master_nodes}"
    availability_zones      = "${var.availability_zones}"
    volume_name             = "${var.volume_name}"
    elasticsearch_data_dir  = "/mnt/elasticsearch/data"
    elasticsearch_logs_dir  = "/mnt/elasticsearch/logs"
    consul_log_file         = "${var.consul_log_file}"
    log_group_name          = "${var.log_group_name}"
    log_stream_name         = "${var.log_stream_name}"
  }
}

resource "aws_iam_instance_profile" "elasticsearch_server_profile" {
    name = "elasticsearch-server-profile"
    role = "${aws_iam_role.elasticsearch_server_role.name}"
}

resource "aws_iam_role" "elasticsearch_server_role" {
  name = "elasticsearch-server-role"

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

resource "aws_iam_role_policy" "elasticsearch_server_role_policy" {
  name = "elasticsearch-server-role-policy"
  role = "${aws_iam_role.elasticsearch_server_role.id}"

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

data "aws_ami" "elasticsearch" {
  most_recent = true

  filter {
    name = "name"
    values = ["elasticsearch-${var.elasticsearch_version}-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["${var.account_id}"]
}

resource "aws_instance" "elasticsearch_server_a" {
  instance_type = "${var.elasticsearch_instance_type}"

  ami = "${data.aws_ami.elasticsearch.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-a-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.elasticsearch_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.elasticsearch_server_profile.name}"

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
    Name = "elasticsearch-server-a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "elasticsearch_server_b" {
  instance_type = "${var.elasticsearch_instance_type}"

  ami = "${data.aws_ami.elasticsearch.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-b-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.elasticsearch_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.elasticsearch_server_profile.name}"

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
    Name = "elasticsearch-server-b"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_volume_attachment" "elasticsearch_volume_attachment_a" {
  device_name = "${var.volume_name}"
  volume_id = "${data.terraform_remote_state.volumes.elasticsearch-volume-a-id}"
  instance_id = "${aws_instance.elasticsearch_server_a.id}"
  skip_destroy = true
}

resource "aws_volume_attachment" "elasticsearch_volume_attachment_b" {
  device_name = "${var.volume_name}"
  volume_id = "${data.terraform_remote_state.volumes.elasticsearch-volume-b-id}"
  instance_id = "${aws_instance.elasticsearch_server_b.id}"
  skip_destroy = true
}

resource "null_resource" "elasticsearch_server_a" {
  depends_on = ["aws_volume_attachment.elasticsearch_volume_attachment_a"]

  triggers {
    cluster_instance_ids = "${join(",", aws_instance.elasticsearch_server_a.*.id)}"
  }

  connection {
    host = "${element(aws_instance.elasticsearch_server_a.*.private_ip, 0)}"
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
    bastion_user = "ec2-user"
    bastion_host = "bastion.${var.public_hosted_zone_name}"
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.elasticsearch_server_user_data.rendered}"
  }
}

resource "null_resource" "elasticsearch_server_b" {
  depends_on = ["aws_volume_attachment.elasticsearch_volume_attachment_b"]

  triggers {
    cluster_instance_ids = "${join(",", aws_instance.elasticsearch_server_b.*.id)}"
  }

  connection {
    host = "${element(aws_instance.elasticsearch_server_b.*.private_ip, 0)}"
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
    bastion_user = "ec2-user"
    bastion_host = "bastion.${var.public_hosted_zone_name}"
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.elasticsearch_server_user_data.rendered}"
  }
}

##############################################################################
# Route 53
##############################################################################

resource "aws_route53_record" "elasticsearch" {
   zone_id = "${data.terraform_remote_state.vpc.hosted-zone-id}"
   name = "elasticsearch.${var.hosted_zone_name}"
   type = "A"
   ttl = "300"

   records = [
     "${aws_instance.elasticsearch_server_a.private_ip}",
     "${aws_instance.elasticsearch_server_b.private_ip}"
   ]
}
