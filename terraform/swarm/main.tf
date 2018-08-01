##############################################################################
# Providers
##############################################################################

provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
  version = "~> 0.1"
}

provider "template" {
  version = "~> 0.1"
}

##############################################################################
# Resources
##############################################################################

resource "aws_security_group" "swarm" {
  name        = "${var.environment}-${var.colour}-swarm"
  description = "Swarm security group"
  vpc_id      = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.aws_bastion_vpc_cidr}","${var.aws_network_vpc_cidr}","${var.aws_openvpn_vpc_cidr}"]
  }

  ingress {
    from_port   = 2376
    to_port     = 2376
    protocol    = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}","${var.aws_openvpn_vpc_cidr}"]
  }

  ingress {
    from_port   = 2377
    to_port     = 2377
    protocol    = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}","${var.aws_openvpn_vpc_cidr}"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.aws_network_vpc_cidr}","${var.aws_openvpn_vpc_cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
  }
}

resource "aws_iam_role" "swarm" {
  name = "${var.environment}-${var.colour}-swarm"

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

resource "aws_iam_role_policy" "swarm" {
  name = "${var.environment}-${var.colour}-swarm"
  role = "${aws_iam_role.swarm.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Action": [
            "ec2:DescribeInstances",
            "ec2messages:GetMessages"
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

# {
#     "Action": [
#         "ssm:UpdateInstanceInformation",
#         "ssm:ListAssociations",
#         "ssm:ListInstanceAssociations"
#     ],
#     "Effect": "Allow",
#     "Resource": "*"
# }

resource "aws_iam_instance_profile" "swarm" {
  name = "${var.environment}-${var.colour}-swarm"
  role = "${aws_iam_role.swarm.name}"
}

data "aws_ami" "swarm" {
  most_recent = true

  filter {
    name   = "name"
    values = ["docker-${var.environment}-${var.colour}-${var.base_version}-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["${var.account_id}"]
}

data "template_file" "swarm-manager" {
  template = "${file("provision/swarm-manager.tpl")}"

  vars {
    aws_region        = "${var.aws_region}"
    environment       = "${var.environment}"
    colour            = "${var.colour}"
    bucket_name       = "${var.secrets_bucket_name}"
    hosted_zone_name  = "${var.hosted_zone_name}"
    hosted_zone_dns   = "${replace(var.aws_network_vpc_cidr, "0/16", "2")}"
  }
}

data "template_file" "swarm-worker" {
  template = "${file("provision/swarm-worker.tpl")}"

  vars {
    aws_region        = "${var.aws_region}"
    environment       = "${var.environment}"
    colour            = "${var.colour}"
    bucket_name       = "${var.secrets_bucket_name}"
    hosted_zone_name  = "${var.hosted_zone_name}"
    hosted_zone_dns   = "${replace(var.aws_network_vpc_cidr, "0/16", "2")}"
  }
}

resource "aws_instance" "swarm_manager_a" {
  ami                         = "${data.aws_ami.swarm.id}"
  instance_type               = "${var.swarm_manager_instance_type}"
  subnet_id                   = "${data.terraform_remote_state.network.network-private-subnet-a-id}"
  private_ip                  = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "150")}"
  vpc_security_group_ids      = ["${aws_security_group.swarm.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.swarm.id}"
  user_data                   = "${data.template_file.swarm-manager.rendered}"
  associate_public_ip_address = "false"
  key_name                    = "${var.environment}-${var.colour}-${var.key_name}"

  root_block_device {
    volume_size = 20
  }

  tags {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-swarm-manager-a"
  }
}

resource "aws_instance" "swarm_manager_b" {
  ami                         = "${data.aws_ami.swarm.id}"
  instance_type               = "${var.swarm_manager_instance_type}"
  subnet_id                   = "${data.terraform_remote_state.network.network-private-subnet-b-id}"
  private_ip                  = "${replace(var.aws_network_private_subnet_cidr_b, "0/24", "150")}"
  vpc_security_group_ids      = ["${aws_security_group.swarm.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.swarm.id}"
  user_data                   = "${data.template_file.swarm-manager.rendered}"
  associate_public_ip_address = "false"
  key_name                    = "${var.environment}-${var.colour}-${var.key_name}"

  root_block_device {
    volume_size = 20
  }

  tags {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-swarm-manager-b"
  }
}

resource "aws_instance" "swarm_manager_c" {
  ami                         = "${data.aws_ami.swarm.id}"
  instance_type               = "${var.swarm_manager_instance_type}"
  subnet_id                   = "${data.terraform_remote_state.network.network-private-subnet-c-id}"
  private_ip                  = "${replace(var.aws_network_private_subnet_cidr_c, "0/24", "150")}"
  vpc_security_group_ids      = ["${aws_security_group.swarm.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.swarm.id}"
  user_data                   = "${data.template_file.swarm-manager.rendered}"
  associate_public_ip_address = "false"
  key_name                    = "${var.environment}-${var.colour}-${var.key_name}"

  root_block_device {
    volume_size = 20
  }

  tags {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-swarm-manager-c"
  }
}

resource "aws_instance" "swarm_worker_a" {
  ami                         = "${data.aws_ami.swarm.id}"
  instance_type               = "${var.swarm_worker_instance_type}"
  subnet_id                   = "${data.terraform_remote_state.network.network-private-subnet-a-id}"
  private_ip                  = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "151")}"
  vpc_security_group_ids      = ["${aws_security_group.swarm.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.swarm.id}"
  user_data                   = "${data.template_file.swarm-worker.rendered}"
  associate_public_ip_address = "false"
  key_name                    = "${var.environment}-${var.colour}-${var.key_name}"

  root_block_device {
    volume_size = 40
  }

  tags {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-swarm-worker-a"
  }
}

resource "aws_instance" "swarm_worker_b" {
  ami                         = "${data.aws_ami.swarm.id}"
  instance_type               = "${var.swarm_worker_instance_type}"
  subnet_id                   = "${data.terraform_remote_state.network.network-private-subnet-b-id}"
  private_ip                  = "${replace(var.aws_network_private_subnet_cidr_b, "0/24", "151")}"
  vpc_security_group_ids      = ["${aws_security_group.swarm.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.swarm.id}"
  user_data                   = "${data.template_file.swarm-worker.rendered}"
  associate_public_ip_address = "false"
  key_name                    = "${var.environment}-${var.colour}-${var.key_name}"

  root_block_device {
    volume_size = 40
  }

  tags {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-swarm-worker-b"
  }
}

resource "aws_instance" "swarm_worker_c" {
  ami                         = "${data.aws_ami.swarm.id}"
  instance_type               = "${var.swarm_worker_instance_type}"
  subnet_id                   = "${data.terraform_remote_state.network.network-private-subnet-c-id}"
  private_ip                  = "${replace(var.aws_network_private_subnet_cidr_c, "0/24", "151")}"
  vpc_security_group_ids      = ["${aws_security_group.swarm.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.swarm.id}"
  user_data                   = "${data.template_file.swarm-worker.rendered}"
  associate_public_ip_address = "false"
  key_name                    = "${var.environment}-${var.colour}-${var.key_name}"

  root_block_device {
    volume_size = 40
  }

  tags {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-swarm-worker-c"
  }
}

# resource "aws_launch_configuration" "swarm-worker" {
#   name_prefix                 = "${var.environment}-${var.colour}-swarm-worker-"
#   image_id                    = "${data.aws_ami.swarm.id}"
#   instance_type               = "${var.swarm_worker_instance_type}"
#   security_groups             = ["${aws_security_group.swarm.id}"]
#   iam_instance_profile        = "${aws_iam_instance_profile.swarm.id}"
#   user_data                   = "${data.template_file.swarm-worker.rendered}"
#   associate_public_ip_address = "false"
#
#   lifecycle {
#     create_before_destroy = true
#   }
# }
#
# resource "aws_autoscaling_group" "swarm-worker" {
#   name                      = "${var.environment}-${var.colour}-swarm-worker"
#   max_size                  = 12
#   min_size                  = 0
#   health_check_grace_period = 300
#   health_check_type         = "EC2"
#   desired_capacity          = 0
#   force_delete              = true
#   launch_configuration      = "${aws_launch_configuration.swarm-worker.name}"
#   vpc_zone_identifier       = [
#     "${data.terraform_remote_state.network.network-private-subnet-a-id}",
#     "${data.terraform_remote_state.network.network-private-subnet-b-id}",
#     "${data.terraform_remote_state.network.network-private-subnet-c-id}"
#   ]
#
#   lifecycle {
#     create_before_destroy   = true
#   }
#
#   tag {
#     key                     = "Environment"
#     value                   = "${var.environment}"
#     propagate_at_launch     = true
#   }
#
#   tag {
#     key                     = "Colour"
#     value                   = "${var.colour}"
#     propagate_at_launch     = true
#   }
#
#   tag {
#     key                     = "Name"
#     value                   = "${var.environment}-${var.colour}-swarm-worker"
#     propagate_at_launch     = true
#   }
#
#   timeouts {
#     delete = "15m"
#   }
# }

resource "aws_route53_record" "swarm-manager" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-swarm-manager.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"
  records = [
    "${aws_instance.swarm_manager_a.private_ip}",
    "${aws_instance.swarm_manager_b.private_ip}",
    "${aws_instance.swarm_manager_c.private_ip}"
  ]
}

resource "aws_route53_record" "swarm-worker" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-swarm-worker.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"
  records = [
    "${aws_instance.swarm_worker_a.private_ip}",
    "${aws_instance.swarm_worker_b.private_ip}",
    "${aws_instance.swarm_worker_c.private_ip}"
  ]
}
