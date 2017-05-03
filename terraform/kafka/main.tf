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
  name = "kafka server"
  description = "kafka server security group"
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
    Name = "kafka server security group"
    Stream = "${var.stream_tag}"
  }
}

data "template_file" "kafka_server_user_data" {
  template = "${file("provision/kafka.tpl")}"

  vars {
    aws_region              = "${var.aws_region}"
    security_groups         = "${aws_security_group.kafka_server.id}"
    consul_log_file         = "${var.consul_log_file}"
    log_group_name          = "${var.log_group_name}"
    log_stream_name         = "${var.log_stream_name}"
    zookeeper_nodes         = "${data.terraform_remote_state.zookeeper.zookeeper-server-a-private-ip}:2181,${data.terraform_remote_state.zookeeper.zookeeper-server-b-private-ip}:2181,${data.terraform_remote_state.zookeeper.zookeeper-server-c-private-ip}:2181"
  }
}

resource "aws_iam_instance_profile" "kafka_node_profile" {
    name = "kafka_node_profile"
    roles = ["${aws_iam_role.kafka_node_role.name}"]
}

resource "aws_iam_role" "kafka_node_role" {
  name = "kafka_node_role"

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

resource "aws_iam_role_policy" "kafka_node_role_policy" {
  name = "kafka_node_role_policy"
  role = "${aws_iam_role.kafka_node_role.id}"

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

resource "aws_instance" "kafka_server_a" {
  instance_type = "${var.aws_kafka_instance_type}"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.kafka_amis, var.aws_region)}"

  subnet_id = "${data.terraform_remote_state.network.network-private-subnet-a-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.kafka_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.kafka_node_profile.name}"

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
    Name = "kafka_server_a"
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
  instance_type = "${var.aws_kafka_instance_type}"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.kafka_amis, var.aws_region)}"

  subnet_id = "${data.terraform_remote_state.network.network-private-subnet-b-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.kafka_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.kafka_node_profile.name}"

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
    Name = "kafka_server_b"
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
  instance_type = "${var.aws_kafka_instance_type}"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.kafka_amis, var.aws_region)}"

  subnet_id = "${data.terraform_remote_state.network.network-private-subnet-c-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.kafka_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.kafka_node_profile.name}"

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
    Name = "kafka_server_c"
    Stream = "${var.stream_tag}"
  }

  provisioner "remote-exec" {
    inline = "sudo echo 3 >/tmp/brokerid"
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.kafka_server_user_data.rendered}"
  }
}
