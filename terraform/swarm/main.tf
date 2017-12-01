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
# Swarm server
##############################################################################

resource "aws_security_group" "swarm_server" {
  name = "swarm-security-group"
  description = "swarm security group"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.aws_bastion_vpc_cidr}"]
  }

  ingress {
    from_port = 2376
    to_port = 2376
    protocol = "tcp"
    cidr_blocks = ["${var.aws_bastion_vpc_cidr}"]
  }

  ingress {
    from_port = 4789
    to_port = 4789
    protocol = "udp"
    cidr_blocks = ["${var.aws_bastion_vpc_cidr}"]
  }

  ingress {
    from_port = 7946
    to_port = 7946
    protocol = "tcp"
    cidr_blocks = ["${var.aws_bastion_vpc_cidr}"]
  }

  ingress {
    from_port = 7946
    to_port = 7946
    protocol = "udp"
    cidr_blocks = ["${var.aws_bastion_vpc_cidr}"]
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

data "template_file" "swarm_server_user_data" {
  template = "${file("provision/swarm.tpl")}"

  vars {
    aws_region                    = "${var.aws_region}"
    environment                   = "${var.environment}"
    bucket_name                   = "${var.secrets_bucket_name}"
    cluster_name                  = "${aws_ecs_cluster.services.name}"
    consul_secret                 = "${var.consul_secret}"
    consul_datacenter             = "${var.consul_datacenter}"
    consul_hostname               = "${var.consul_record}.${var.hosted_zone_name}"
    consul_log_file               = "${var.consul_log_file}"
    logstash_host                 = "logstash.${var.hosted_zone_name}"
    filebeat_version              = "${var.filebeat_version}"
    security_groups               = "${aws_security_group.swarm_server.id}"
    hosted_zone_name              = "${var.hosted_zone_name}"
    public_hosted_zone_name       = "${var.public_hosted_zone_name}"
  }
}

resource "aws_iam_instance_profile" "swarm_server_profile" {
    name = "swarm-server-profile"
    role = "${aws_iam_role.swarm_server_role.name}"
}

resource "aws_iam_role" "swarm_server_role" {
  name = "swarm-server-role"

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

resource "aws_iam_role_policy" "swarm_server_role_policy" {
  name = "swarm-server-role-policy"
  role = "${aws_iam_role.swarm_server_role.id}"

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

data "aws_ami" "swarm" {
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

resource "aws_instance" "swarm_master_a" {
  instance_type = "${var.swarm_instance_type}"

  ami = "${data.aws_ami.swarm.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-a-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.swarm_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.swarm_server_profile.id}"

  user_data = "${data.template_file.swarm_server_user_data.rendered}"

  private_ip = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "150")}"

  tags {
    Name = "swarm-master-a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "swarm_worker1_a" {
  instance_type = "${var.swarm_instance_type}"

  ami = "${data.aws_ami.swarm.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-a-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.swarm_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.swarm_server_profile.id}"

  user_data = "${data.template_file.swarm_server_user_data.rendered}"

  private_ip = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "151")}"

  tags {
    Name = "swarm-worker1-a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "swarm_worker2_a" {
  instance_type = "${var.swarm_instance_type}"

  ami = "${data.aws_ami.swarm.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-a-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.swarm_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.swarm_server_profile.id}"

  user_data = "${data.template_file.swarm_server_user_data.rendered}"

  private_ip = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "152")}"

  tags {
    Name = "swarm-worker2-a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "swarm_master_b" {
  instance_type = "${var.swarm_instance_type}"

  ami = "${data.aws_ami.swarm.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-a-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.swarm_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.swarm_server_profile.id}"

  user_data = "${data.template_file.swarm_server_user_data.rendered}"

  private_ip = "${replace(var.aws_network_private_subnet_cidr_b, "0/24", "150")}"

  tags {
    Name = "swarm-master-b"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "swarm_worker1_b" {
  instance_type = "${var.swarm_instance_type}"

  ami = "${data.aws_ami.swarm.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-a-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.swarm_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.swarm_server_profile.id}"

  user_data = "${data.template_file.swarm_server_user_data.rendered}"

  private_ip = "${replace(var.aws_network_private_subnet_cidr_b, "0/24", "151")}"

  tags {
    Name = "swarm-worker1-b"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "swarm_worker2_b" {
  instance_type = "${var.swarm_instance_type}"

  ami = "${data.aws_ami.swarm.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-a-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.swarm_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.swarm_server_profile.id}"

  user_data = "${data.template_file.swarm_server_user_data.rendered}"

  private_ip = "${replace(var.aws_network_private_subnet_cidr_b, "0/24", "152")}"

  tags {
    Name = "swarm-worker2-b"
    Stream = "${var.stream_tag}"
  }
}
