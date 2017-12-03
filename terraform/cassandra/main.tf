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
# Cassandra servers
##############################################################################

resource "aws_security_group" "cassandra_server" {
  name = "cassandra-security-group"
  description = "Cassandra security group"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.aws_bastion_vpc_cidr}"]
  }

  ingress {
    from_port = 7000
    to_port = 7001
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 7199
    to_port = 7199
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 9042
    to_port = 9042
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 9142
    to_port = 9142
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 9160
    to_port = 9160
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

resource "aws_iam_instance_profile" "cassandra_server_profile" {
    name = "cassandra-server-profile"
    role = "${aws_iam_role.cassandra_server_role.name}"
}

resource "aws_iam_role" "cassandra_server_role" {
  name = "cassandra-server-role"

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

resource "aws_iam_role_policy" "cassandra_server_role_policy" {
  name = "cassandra-server-role-policy"
  role = "${aws_iam_role.cassandra_server_role.id}"

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

data "template_file" "cassandra_server_user_data_seed" {
  template = "${file("provision/cassandra-seed.tpl")}"

  vars {
    security_groups         = "${aws_security_group.cassandra_server.id}"
    environment             = "${var.environment}"
    bucket_name             = "${var.secrets_bucket_name}"
    consul_datacenter       = "${var.consul_datacenter}"
    consul_hostname         = "${var.consul_record}.${var.hosted_zone_name}"
    consul_log_file         = "${var.consul_log_file}"
    consul_secret           = "${var.consul_secret}"
    hosted_zone_name        = "${var.hosted_zone_name}"
    public_hosted_zone_name = "${var.public_hosted_zone_name}"
    logstash_host           = "logstash.${var.hosted_zone_name}"
    filebeat_version        = "${var.filebeat_version}"
    cassandra_version       = "${var.cassandra_version}"
    cassandra_nodes         = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "70")},${replace(var.aws_network_private_subnet_cidr_b, "0/24", "70")},${replace(var.aws_network_private_subnet_cidr_c, "0/24", "70")}"
  }
}

data "template_file" "cassandra_server_user_data_node" {
  template = "${file("provision/cassandra-node.tpl")}"

  vars {
    security_groups         = "${aws_security_group.cassandra_server.id}"
    environment             = "${var.environment}"
    bucket_name             = "${var.secrets_bucket_name}"
    consul_datacenter       = "${var.consul_datacenter}"
    consul_hostname         = "${var.consul_record}.${var.hosted_zone_name}"
    consul_log_file         = "${var.consul_log_file}"
    consul_secret           = "${var.consul_secret}"
    hosted_zone_name        = "${var.hosted_zone_name}"
    public_hosted_zone_name = "${var.public_hosted_zone_name}"
    logstash_host           = "logstash.${var.hosted_zone_name}"
    filebeat_version        = "${var.filebeat_version}"
    cassandra_version       = "${var.cassandra_version}"
    cassandra_nodes         = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "70")},${replace(var.aws_network_private_subnet_cidr_b, "0/24", "70")},${replace(var.aws_network_private_subnet_cidr_c, "0/24", "70")}"
  }
}

data "aws_ami" "cassandra" {
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

resource "aws_instance" "cassandra_server_a1" {
  instance_type = "${var.cassandra_instance_type}"

  ami = "${data.aws_ami.cassandra.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-a-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.cassandra_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.cassandra_server_profile.id}"

  user_data = "${data.template_file.cassandra_server_user_data_seed.rendered}"

  private_ip = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "70")}"

  tags {
    Name = "cassandra-server-a1"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "cassandra_server_b1" {
  instance_type = "${var.cassandra_instance_type}"

  ami = "${data.aws_ami.cassandra.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-b-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.cassandra_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.cassandra_server_profile.id}"

  user_data = "${data.template_file.cassandra_server_user_data_seed.rendered}"

  private_ip = "${replace(var.aws_network_private_subnet_cidr_b, "0/24", "70")}"

  tags {
    Name = "cassandra-server-b1"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "cassandra_server_c1" {
  instance_type = "${var.cassandra_instance_type}"

  ami = "${data.aws_ami.cassandra.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-c-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.cassandra_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.cassandra_server_profile.id}"

  user_data = "${data.template_file.cassandra_server_user_data_seed.rendered}"

  private_ip = "${replace(var.aws_network_private_subnet_cidr_c, "0/24", "70")}"

  tags {
    Name = "cassandra-server-c1"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "cassandra_server_a2" {
  instance_type = "${var.cassandra_instance_type}"

  ami = "${data.aws_ami.cassandra.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-a-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.cassandra_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.cassandra_server_profile.id}"

  user_data = "${data.template_file.cassandra_server_user_data_node.rendered}"

  private_ip = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "72")}"

  tags {
    Name = "cassandra-server-a2"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "cassandra_server_b2" {
  instance_type = "${var.cassandra_instance_type}"

  ami = "${data.aws_ami.cassandra.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-b-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.cassandra_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.cassandra_server_profile.id}"

  user_data = "${data.template_file.cassandra_server_user_data_node.rendered}"

  private_ip = "${replace(var.aws_network_private_subnet_cidr_b, "0/24", "72")}"

  tags {
    Name = "cassandra-server-b2"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "cassandra_server_c2" {
  instance_type = "${var.cassandra_instance_type}"

  ami = "${data.aws_ami.cassandra.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-c-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.cassandra_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.cassandra_server_profile.id}"

  user_data = "${data.template_file.cassandra_server_user_data_node.rendered}"

  private_ip = "${replace(var.aws_network_private_subnet_cidr_c, "0/24", "72")}"

  tags {
    Name = "cassandra-server-c2"
    Stream = "${var.stream_tag}"
  }
}
