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
    cidr_blocks = ["${var.aws_network_vpc_cidr}","${var.aws_openvpn_vpc_cidr}"]
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
    },
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "route53.amazonaws.com"
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
    },
    {
        "Action": [
            "route53:ChangeResourceRecordSets"
        ],
        "Effect": "Allow",
        "Resource": "arn:aws:route53:::hostedzone/${var.hosted_zone_id}"
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

data "template_file" "swarm-worker-int" {
  template = "${file("provision/swarm-worker-int.tpl")}"

  vars {
    aws_region        = "${var.aws_region}"
    environment       = "${var.environment}"
    colour            = "${var.colour}"
    bucket_name       = "${var.secrets_bucket_name}"
    hosted_zone_name  = "${var.hosted_zone_name}"
    hosted_zone_dns   = "${replace(var.aws_network_vpc_cidr, "0/16", "2")}"
  }
}

data "template_file" "swarm-worker-ext-a" {
  template = "${file("provision/swarm-worker-ext.tpl")}"

  vars {
    aws_region        = "${var.aws_region}"
    environment       = "${var.environment}"
    colour            = "${var.colour}"
    bucket_name       = "${var.secrets_bucket_name}"
    hosted_zone_name  = "${var.hosted_zone_name}"
    hosted_zone_id    = "${var.hosted_zone_id}"
    hosted_zone_dns   = "${replace(var.aws_network_vpc_cidr, "0/16", "2")}"
    swarm_ext_dns     = "${var.environment}-${var.colour}-swarm-worker-ext-pub-a.${var.hosted_zone_name}"
  }
}

data "template_file" "swarm-worker-ext-b" {
  template = "${file("provision/swarm-worker-ext.tpl")}"

  vars {
    aws_region        = "${var.aws_region}"
    environment       = "${var.environment}"
    colour            = "${var.colour}"
    bucket_name       = "${var.secrets_bucket_name}"
    hosted_zone_name  = "${var.hosted_zone_name}"
    hosted_zone_id    = "${var.hosted_zone_id}"
    hosted_zone_dns   = "${replace(var.aws_network_vpc_cidr, "0/16", "2")}"
    swarm_ext_dns     = "${var.environment}-${var.colour}-swarm-worker-ext-pub-b.${var.hosted_zone_name}"
  }
}

data "template_file" "swarm-worker-ext-c" {
  template = "${file("provision/swarm-worker-ext.tpl")}"

  vars {
    aws_region        = "${var.aws_region}"
    environment       = "${var.environment}"
    colour            = "${var.colour}"
    bucket_name       = "${var.secrets_bucket_name}"
    hosted_zone_name  = "${var.hosted_zone_name}"
    hosted_zone_id    = "${var.hosted_zone_id}"
    hosted_zone_dns   = "${replace(var.aws_network_vpc_cidr, "0/16", "2")}"
    swarm_ext_dns     = "${var.environment}-${var.colour}-swarm-worker-ext-pub-c.${var.hosted_zone_name}"
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
    volume_type = "${var.volume_type}"
    volume_size = "${var.manager_volume_size}"
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
    volume_type = "${var.volume_type}"
    volume_size = "${var.manager_volume_size}"
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
    volume_type = "${var.volume_type}"
    volume_size = "${var.manager_volume_size}"
  }

  tags {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-swarm-manager-c"
  }
}

resource "aws_instance" "swarm_worker_int_a" {
  ami                         = "${data.aws_ami.swarm.id}"
  instance_type               = "${var.swarm_worker_int_instance_type}"
  subnet_id                   = "${data.terraform_remote_state.network.network-private-subnet-a-id}"
  private_ip                  = "${replace(var.aws_network_private_subnet_cidr_a, "0/24", "151")}"
  vpc_security_group_ids      = ["${aws_security_group.swarm.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.swarm.id}"
  user_data                   = "${data.template_file.swarm-worker-int.rendered}"
  associate_public_ip_address = "false"
  key_name                    = "${var.environment}-${var.colour}-${var.key_name}"

  root_block_device {
    volume_type = "${var.volume_type}"
    volume_size = "${var.worker_volume_size}"
  }

  tags {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-swarm-worker-int-a"
  }
}

resource "aws_instance" "swarm_worker_int_b" {
  ami                         = "${data.aws_ami.swarm.id}"
  instance_type               = "${var.swarm_worker_int_instance_type}"
  subnet_id                   = "${data.terraform_remote_state.network.network-private-subnet-b-id}"
  private_ip                  = "${replace(var.aws_network_private_subnet_cidr_b, "0/24", "151")}"
  vpc_security_group_ids      = ["${aws_security_group.swarm.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.swarm.id}"
  user_data                   = "${data.template_file.swarm-worker-int.rendered}"
  associate_public_ip_address = "false"
  key_name                    = "${var.environment}-${var.colour}-${var.key_name}"

  root_block_device {
    volume_type = "${var.volume_type}"
    volume_size = "${var.worker_volume_size}"
  }

  tags {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-swarm-worker-int-b"
  }
}

resource "aws_instance" "swarm_worker_int_c" {
  ami                         = "${data.aws_ami.swarm.id}"
  instance_type               = "${var.swarm_worker_int_instance_type}"
  subnet_id                   = "${data.terraform_remote_state.network.network-private-subnet-c-id}"
  private_ip                  = "${replace(var.aws_network_private_subnet_cidr_c, "0/24", "151")}"
  vpc_security_group_ids      = ["${aws_security_group.swarm.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.swarm.id}"
  user_data                   = "${data.template_file.swarm-worker-int.rendered}"
  associate_public_ip_address = "false"
  key_name                    = "${var.environment}-${var.colour}-${var.key_name}"

  root_block_device {
    volume_type = "${var.volume_type}"
    volume_size = "${var.worker_volume_size}"
  }

  tags {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-swarm-worker-int-c"
  }
}

resource "aws_instance" "swarm_worker_ext_a" {
  ami                         = "${data.aws_ami.swarm.id}"
  instance_type               = "${var.swarm_worker_ext_instance_type}"
  subnet_id                   = "${data.terraform_remote_state.network.network-public-subnet-a-id}"
  private_ip                  = "${replace(var.aws_network_public_subnet_cidr_a, "0/24", "152")}"
  vpc_security_group_ids      = ["${aws_security_group.swarm.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.swarm.id}"
  user_data                   = "${data.template_file.swarm-worker-ext-a.rendered}"
  associate_public_ip_address = "true"
  key_name                    = "${var.environment}-${var.colour}-${var.key_name}"

  root_block_device {
    volume_type = "${var.volume_type}"
    volume_size = "${var.worker_volume_size}"
  }

  tags {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-swarm-worker-ext-a"
  }
}

resource "aws_instance" "swarm_worker_ext_b" {
  ami                         = "${data.aws_ami.swarm.id}"
  instance_type               = "${var.swarm_worker_ext_instance_type}"
  subnet_id                   = "${data.terraform_remote_state.network.network-public-subnet-b-id}"
  private_ip                  = "${replace(var.aws_network_public_subnet_cidr_b, "0/24", "152")}"
  vpc_security_group_ids      = ["${aws_security_group.swarm.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.swarm.id}"
  user_data                   = "${data.template_file.swarm-worker-ext-b.rendered}"
  associate_public_ip_address = "true"
  key_name                    = "${var.environment}-${var.colour}-${var.key_name}"

  root_block_device {
    volume_type = "${var.volume_type}"
    volume_size = "${var.worker_volume_size}"
  }

  tags {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-swarm-worker-ext-b"
  }
}

resource "aws_instance" "swarm_worker_ext_c" {
  ami                         = "${data.aws_ami.swarm.id}"
  instance_type               = "${var.swarm_worker_ext_instance_type}"
  subnet_id                   = "${data.terraform_remote_state.network.network-public-subnet-c-id}"
  private_ip                  = "${replace(var.aws_network_public_subnet_cidr_c, "0/24", "152")}"
  vpc_security_group_ids      = ["${aws_security_group.swarm.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.swarm.id}"
  user_data                   = "${data.template_file.swarm-worker-ext-c.rendered}"
  associate_public_ip_address = "true"
  key_name                    = "${var.environment}-${var.colour}-${var.key_name}"

  root_block_device {
    volume_type = "${var.volume_type}"
    volume_size = "${var.worker_volume_size}"
  }

  tags {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-swarm-worker-ext-c"
  }
}

# resource "aws_launch_configuration" "swarm_worker_launch_configuration" {
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
# resource "aws_autoscaling_group" "swarm_worker_asg" {
#   name                      = "${var.environment}-${var.colour}-swarm-worker"
#   max_size                  = 12
#   min_size                  = 0
#   health_check_grace_period = 300
#   health_check_type         = "EC2"
#   desired_capacity          = 0
#   force_delete              = true
#   launch_configuration      = "${aws_launch_configuration.swarm_worker_launch_configuration.name}"
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
#     value                   = "${var.environment}-${var.colour}-swarm-worker-int"
#     propagate_at_launch     = true
#   }
#
#   timeouts {
#     delete = "15m"
#   }
# }

resource "aws_route53_record" "swarm_manager" {
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

resource "aws_route53_record" "swarm_worker_int" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-swarm-worker-int.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${aws_instance.swarm_worker_int_a.private_ip}",
    "${aws_instance.swarm_worker_int_b.private_ip}",
    "${aws_instance.swarm_worker_int_c.private_ip}"
  ]
}

resource "aws_route53_record" "swarm_worker_pub" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-swarm-worker-ext.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${aws_instance.swarm_worker_ext_a.private_ip}",
    "${aws_instance.swarm_worker_ext_b.private_ip}",
    "${aws_instance.swarm_worker_ext_c.private_ip}"
  ]
}

resource "aws_route53_record" "swarm_manager_a" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-swarm-manager-a.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${aws_instance.swarm_manager_a.private_ip}",
  ]
}

resource "aws_route53_record" "swarm_manager_b" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-swarm-manager-b.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${aws_instance.swarm_manager_b.private_ip}"
  ]
}

resource "aws_route53_record" "swarm_manager_c" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-swarm-manager-c.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${aws_instance.swarm_manager_c.private_ip}"
  ]
}

resource "aws_route53_record" "swarm_worker_int_a" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-swarm-worker-int-a.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${aws_instance.swarm_worker_int_a.private_ip}"
  ]
}

resource "aws_route53_record" "swarm_worker_int_b" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-swarm-worker-int-b.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${aws_instance.swarm_worker_int_b.private_ip}"
  ]
}

resource "aws_route53_record" "swarm_worker_int_c" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-swarm-worker-int-c.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${aws_instance.swarm_worker_int_c.private_ip}"
  ]
}

resource "aws_route53_record" "swarm_worker_ext_a" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-swarm-worker-ext-a.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${aws_instance.swarm_worker_ext_a.private_ip}"
  ]
}

resource "aws_route53_record" "swarm_worker_ext_b" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-swarm-worker-ext-b.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${aws_instance.swarm_worker_ext_b.private_ip}"
  ]
}

resource "aws_route53_record" "swarm_worker_ext_c" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-swarm-worker-ext-c.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${aws_instance.swarm_worker_ext_c.private_ip}"
  ]
}

resource "aws_route53_record" "swarm_worker_ext_pub_a" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-swarm-worker-ext-pub-a.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${aws_instance.swarm_worker_ext_a.public_ip}"
  ]
}

resource "aws_route53_record" "swarm_worker_ext_pub_b" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-swarm-worker-ext-pub-b.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${aws_instance.swarm_worker_ext_b.public_ip}"
  ]
}

resource "aws_route53_record" "swarm_worker_ext_pub_c" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-swarm-worker-ext-pub-c.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${aws_instance.swarm_worker_ext_c.public_ip}"
  ]
}
