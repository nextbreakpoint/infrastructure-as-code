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
# Pipeline server
##############################################################################

resource "aws_security_group" "pipeline_server" {
  name = "pipeline-security-group"
  description = "Pipeline security group"
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
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 8443
    to_port = 8443
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 8081
    to_port = 8081
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 9000
    to_port = 9000
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 3306
    to_port = 3306
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

data "template_file" "pipeline_server_user_data" {
  template = "${file("provision/pipeline.tpl")}"

  vars {
    aws_region                    = "${var.aws_region}"
    environment                   = "${var.environment}"
    bucket_name                   = "${var.secrets_bucket_name}"
    consul_secret                 = "${var.consul_secret}"
    consul_datacenter             = "${var.consul_datacenter}"
    consul_hostname               = "${var.consul_record}.${var.hosted_zone_name}"
    consul_log_file               = "${var.consul_log_file}"
    security_groups               = "${aws_security_group.pipeline_server.id}"
    hosted_zone_name              = "${var.hosted_zone_name}"
    public_hosted_zone_name       = "${var.public_hosted_zone_name}"
    logstash_host                 = "logstash.${var.hosted_zone_name}"
    volume_name                   = "${var.volume_name}"
    filebeat_version              = "${var.filebeat_version}"
    jenkins_version               = "${var.jenkins_version}"
    sonarqube_version             = "${var.sonarqube_version}"
    artifactory_version           = "${var.artifactory_version}"
    mysqlconnector_version        = "${var.mysqlconnector_version}"
    mysql_root_password           = "${var.mysql_root_password}"
    mysql_sonarqube_password      = "${var.mysql_sonarqube_password}"
    mysql_artifactory_password    = "${var.mysql_artifactory_password}"
  }
}

resource "aws_iam_instance_profile" "pipeline_server_profile" {
    name = "pipeline-server-profile"
    role = "${aws_iam_role.pipeline_server_role.name}"
}

resource "aws_iam_role" "pipeline_server_role" {
  name = "pipeline-server-role"

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

resource "aws_iam_role_policy" "pipeline_server_role_policy" {
  name = "pipeline-server-role-policy"
  role = "${aws_iam_role.pipeline_server_role.id}"

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

data "aws_ami" "pipeline" {
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

resource "aws_instance" "pipeline_server_a" {
  instance_type = "t2.medium"

  ami = "${data.aws_ami.pipeline.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-a-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.pipeline_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.pipeline_server_profile.id}"

  user_data = "${data.template_file.pipeline_server_user_data.rendered}"

  private_ip = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "100")}"

  ebs_block_device {
    device_name = "${var.volume_name}"
    volume_size = "${var.volume_size}"
    volume_type = "gp2"
    encrypted = "${var.volume_encrypted}"
    delete_on_termination = true
  }

  tags {
    Name = "pipeline-server-a"
    Stream = "${var.stream_tag}"
  }
}

##############################################################################
# Route 53
##############################################################################

resource "aws_route53_record" "mysql" {
  zone_id = "${data.terraform_remote_state.vpc.hosted-zone-id}"
  name = "mysql.${var.hosted_zone_name}"
  type = "A"
  ttl = "60"
  records = ["${aws_instance.pipeline_server_a.*.private_ip}"]
}

resource "aws_route53_record" "jenkins" {
  zone_id = "${data.terraform_remote_state.vpc.hosted-zone-id}"
  name = "jenkins.${var.hosted_zone_name}"
  type = "A"
  ttl = "60"
  records = ["${aws_instance.pipeline_server_a.*.private_ip}"]
}

resource "aws_route53_record" "sonarqube" {
  zone_id = "${data.terraform_remote_state.vpc.hosted-zone-id}"
  name = "sonarqube.${var.hosted_zone_name}"
  type = "A"
  ttl = "60"
  records = ["${aws_instance.pipeline_server_a.*.private_ip}"]
}

resource "aws_route53_record" "artifactory" {
  zone_id = "${data.terraform_remote_state.vpc.hosted-zone-id}"
  name = "artifactory.${var.hosted_zone_name}"
  type = "A"
  ttl = "60"
  records = ["${aws_instance.pipeline_server_a.*.private_ip}"]
}
