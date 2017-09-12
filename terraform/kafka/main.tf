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
    key = "kafka.tfstate"
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

data "terraform_remote_state" "zookeeper" {
    backend = "s3"
    config {
        bucket = "nextbreakpoint-terraform-state"
        region = "${var.aws_region}"
        key = "zookeeper.tfstate"
    }
}

##############################################################################
# Kafka servers
##############################################################################

resource "aws_security_group" "kafka_server" {
  name = "kafka-security-group"
  description = "Kafka security group"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.aws_bastion_vpc_cidr}"]
  }

  ingress {
    from_port = 9092
    to_port = 9092
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
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

  egress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  egress {
    from_port = 9092
    to_port = 9092
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  egress {
    from_port = 2181
    to_port = 2181
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  egress {
    from_port = 8300
    to_port = 8302
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  egress {
    from_port = 8300
    to_port = 8302
    protocol = "udp"
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

data "template_file" "kafka_server_user_data" {
  template = "${file("provision/kafka.tpl")}"

  vars {
    aws_region              = "${var.aws_region}"
    security_groups         = "${aws_security_group.kafka_server.id}"
    consul_log_file         = "${var.consul_log_file}"
    kafka_version           = "${var.kafka_version}"
    scala_version           = "${var.scala_version}"
    log_group_name          = "${var.log_group_name}"
    log_stream_name         = "${var.log_stream_name}"
    zookeeper_nodes         = "${data.terraform_remote_state.zookeeper.zookeeper-server-a-private-ip}:2181,${data.terraform_remote_state.zookeeper.zookeeper-server-b-private-ip}:2181,${data.terraform_remote_state.zookeeper.zookeeper-server-c-private-ip}:2181"
  }
}

resource "aws_iam_instance_profile" "kafka_server_profile" {
    name = "kafka-server-profile"
    role = "${aws_iam_role.kafka_server_role.name}"
}

resource "aws_iam_role" "kafka_server_role" {
  name = "kafka-server-role"

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

resource "aws_iam_role_policy" "kafka_server_role_policy" {
  name = "kafka-server-role-policy"
  role = "${aws_iam_role.kafka_server_role.id}"

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

data "aws_ami" "kafka" {
  most_recent = true

  filter {
    name = "name"
    values = ["kafka-${var.kafka_version}-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["${var.account_id}"]
}

resource "aws_instance" "kafka_server_a" {
  instance_type = "${var.kafka_instance_type}"

  ami = "${data.aws_ami.kafka.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-a-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.kafka_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.kafka_server_profile.name}"

  connection {
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
    bastion_user = "ec2-user"
    bastion_host = "bastion.nextbreakpoint.com"
  }

  tags {
    Name = "kafka-server-a"
    Stream = "${var.stream_tag}"
  }

  provisioner "remote-exec" {
    inline = "sudo echo 1 >/tmp/brokerid"
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.kafka_server_user_data.rendered}"
  }
}

resource "aws_instance" "kafka_server_b" {
  instance_type = "${var.kafka_instance_type}"

  ami = "${data.aws_ami.kafka.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-b-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.kafka_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.kafka_server_profile.name}"

  connection {
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
    bastion_user = "ec2-user"
    bastion_host = "bastion.nextbreakpoint.com"
  }

  tags {
    Name = "kafka-server-b"
    Stream = "${var.stream_tag}"
  }

  provisioner "remote-exec" {
    inline = "sudo echo 2 >/tmp/brokerid"
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.kafka_server_user_data.rendered}"
  }
}

resource "aws_instance" "kafka_server_c" {
  instance_type = "${var.kafka_instance_type}"

  ami = "${data.aws_ami.kafka.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-c-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.kafka_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.kafka_server_profile.name}"

  connection {
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
    bastion_user = "ec2-user"
    bastion_host = "bastion.nextbreakpoint.com"
  }

  tags {
    Name = "kafka-server-c"
    Stream = "${var.stream_tag}"
  }

  provisioner "remote-exec" {
    inline = "sudo echo 3 >/tmp/brokerid"
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.kafka_server_user_data.rendered}"
  }
}
