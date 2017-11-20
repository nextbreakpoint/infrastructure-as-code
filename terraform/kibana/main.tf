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
    environment             = "${var.environment}"
    bucket_name             = "${var.secrets_bucket_name}"
    consul_secret           = "${var.consul_secret}"
    consul_datacenter       = "${var.consul_datacenter}"
    consul_hostname         = "${var.consul_record}.${var.hosted_zone_name}"
    consul_log_file         = "${var.consul_log_file}"
    security_groups         = "${aws_security_group.kibana_server.id}"
    minimum_master_nodes    = "${var.minimum_master_nodes}"
    hosted_zone_name        = "${var.hosted_zone_name}"
    public_hosted_zone_name = "${var.public_hosted_zone_name}"
    elasticsearch_host      = "elasticsearch.${var.hosted_zone_name}"
    logstash_host           = "logstash.${var.hosted_zone_name}"
    cluster_name            = "${var.elasticsearch_cluster_name}"
    elasticsearch_version   = "${var.elasticsearch_version}"
    filebeat_version        = "${var.filebeat_version}"
    kibana_version          = "${var.kibana_version}"
    elasticsearch_nodes     = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "10")},${replace(var.aws_network_private_subnet_cidr_b, "0/24", "10")}"
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

data "aws_ami" "kibana" {
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

resource "aws_instance" "kibana_server_a" {
  instance_type = "${var.kibana_instance_type}"

  ami = "${data.aws_ami.kibana.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-a-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.kibana_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.kibana_server_profile.name}"

  user_data = "${data.template_file.kibana_server_user_data.rendered}"

  private_ip = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "40")}"

  tags {
    Name = "kibana-server-a"
    Stream = "${var.stream_tag}"
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

  user_data = "${data.template_file.kibana_server_user_data.rendered}"

  private_ip = "${replace(var.aws_network_private_subnet_cidr_b, "0/24", "40")}"

  tags {
    Name = "kibana-server-b"
    Stream = "${var.stream_tag}"
  }
}

##############################################################################
# Route 53
##############################################################################

resource "aws_route53_record" "kibana_dns" {
  zone_id = "${data.terraform_remote_state.vpc.hosted-zone-id}"
  name = "kibana.${var.hosted_zone_name}"
  type = "A"
  ttl = "60"

  records = [
    "${aws_instance.kibana_server_a.private_ip}"
  ]
}
