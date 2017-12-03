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

data "template_file" "kafka_server_user_data_a" {
  template = "${file("provision/kafka.tpl")}"

  vars {
    broker_id               = "1"
    aws_region              = "${var.aws_region}"
    security_groups         = "${aws_security_group.kafka_server.id}"
    environment             = "${var.environment}"
    bucket_name             = "${var.secrets_bucket_name}"
    consul_secret           = "${var.consul_secret}"
    consul_datacenter       = "${var.consul_datacenter}"
    consul_hostname         = "${var.consul_record}.${var.hosted_zone_name}"
    consul_log_file         = "${var.consul_log_file}"
    hosted_zone_name        = "${var.hosted_zone_name}"
    public_hosted_zone_name = "${var.public_hosted_zone_name}"
    logstash_host           = "logstash.${var.hosted_zone_name}"
    filebeat_version        = "${var.filebeat_version}"
    kafka_version           = "${var.kafka_version}"
    scala_version           = "${var.scala_version}"
    zookeeper_nodes         = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "20")},${replace(var.aws_network_private_subnet_cidr_b, "0/24", "20")},${replace(var.aws_network_private_subnet_cidr_c, "0/24", "20")}"
  }
}

data "template_file" "kafka_server_user_data_b" {
  template = "${file("provision/kafka.tpl")}"

  vars {
    broker_id               = "2"
    aws_region              = "${var.aws_region}"
    security_groups         = "${aws_security_group.kafka_server.id}"
    environment             = "${var.environment}"
    bucket_name             = "${var.secrets_bucket_name}"
    consul_secret           = "${var.consul_secret}"
    consul_datacenter       = "${var.consul_datacenter}"
    consul_hostname         = "${var.consul_record}.${var.hosted_zone_name}"
    consul_log_file         = "${var.consul_log_file}"
    hosted_zone_name        = "${var.hosted_zone_name}"
    public_hosted_zone_name = "${var.public_hosted_zone_name}"
    logstash_host           = "logstash.${var.hosted_zone_name}"
    filebeat_version        = "${var.filebeat_version}"
    kafka_version           = "${var.kafka_version}"
    scala_version           = "${var.scala_version}"
    zookeeper_nodes         = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "20")},${replace(var.aws_network_private_subnet_cidr_b, "0/24", "20")},${replace(var.aws_network_private_subnet_cidr_c, "0/24", "20")}"
  }
}

data "template_file" "kafka_server_user_data_c" {
  template = "${file("provision/kafka.tpl")}"

  vars {
    broker_id               = "3"
    aws_region              = "${var.aws_region}"
    security_groups         = "${aws_security_group.kafka_server.id}"
    environment             = "${var.environment}"
    bucket_name             = "${var.secrets_bucket_name}"
    consul_secret           = "${var.consul_secret}"
    consul_datacenter       = "${var.consul_datacenter}"
    consul_hostname         = "${var.consul_record}.${var.hosted_zone_name}"
    consul_log_file         = "${var.consul_log_file}"
    hosted_zone_name        = "${var.hosted_zone_name}"
    public_hosted_zone_name = "${var.public_hosted_zone_name}"
    logstash_host           = "logstash.${var.hosted_zone_name}"
    filebeat_version        = "${var.filebeat_version}"
    kafka_version           = "${var.kafka_version}"
    scala_version           = "${var.scala_version}"
    zookeeper_nodes         = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "20")},${replace(var.aws_network_private_subnet_cidr_b, "0/24", "20")},${replace(var.aws_network_private_subnet_cidr_c, "0/24", "20")}"
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
    },
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
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
    },
    {
        "Action": [
            "s3:GetObject"
        ],
        "Effect": "Allow",
        "Resource": "arn:aws:s3:::${var.secrets_bucket_name}/*"
    }
  ]
}
EOF
}

data "aws_ami" "kafka" {
  most_recent = true

  filter {
    name = "name"
    values = ["base-${var.base_version}-*"]
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

  user_data = "${data.template_file.kafka_server_user_data_a.rendered}"

  private_ip = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "50")}"

  tags {
    Name = "kafka-server-a"
    Stream = "${var.stream_tag}"
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

  user_data = "${data.template_file.kafka_server_user_data_b.rendered}"

  private_ip = "${replace(var.aws_network_private_subnet_cidr_b, "0/24", "50")}"

  tags {
    Name = "kafka-server-b"
    Stream = "${var.stream_tag}"
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

  user_data = "${data.template_file.kafka_server_user_data_c.rendered}"

  private_ip = "${replace(var.aws_network_private_subnet_cidr_c, "0/24", "50")}"

  tags {
    Name = "kafka-server-c"
    Stream = "${var.stream_tag}"
  }
}
