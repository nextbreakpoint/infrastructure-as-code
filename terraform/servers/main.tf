data "aws_caller_identity" "current" {}

resource "aws_security_group" "server" {
  name        = "${var.environment}-${var.colour}-server"
  description = "Server security group"
  vpc_id      = "${data.terraform_remote_state.vpc.outputs.platform-vpc-id}"

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
    cidr_blocks = ["${data.terraform_remote_state.vpc.outputs.platform-vpc-cidr}","${data.terraform_remote_state.vpc.outputs.openvpn-vpc-cidr}","${data.terraform_remote_state.vpc.outputs.bastion-vpc-cidr}"]
  }

  ingress {
    from_port   = 2376
    to_port     = 2376
    protocol    = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.outputs.platform-vpc-cidr}","${data.terraform_remote_state.vpc.outputs.openvpn-vpc-cidr}"]
  }

  ingress {
    from_port   = 2377
    to_port     = 2377
    protocol    = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.outputs.platform-vpc-cidr}","${data.terraform_remote_state.vpc.outputs.openvpn-vpc-cidr}"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${data.terraform_remote_state.vpc.outputs.platform-vpc-cidr}","${data.terraform_remote_state.vpc.outputs.openvpn-vpc-cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${data.terraform_remote_state.vpc.outputs.platform-vpc-cidr}","${data.terraform_remote_state.vpc.outputs.openvpn-vpc-cidr}"]
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

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
  }
}

resource "aws_iam_role" "server" {
  name = "${var.environment}-${var.colour}-server"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    },
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow"
    },
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "route53.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "server" {
  name = "${var.environment}-${var.colour}-server"
  role = "${aws_iam_role.server.id}"

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
            "route53:ChangeResourceRecordSets"
        ],
        "Effect": "Allow",
        "Resource": [
          "arn:aws:route53:::hostedzone/${var.hosted_zone_id}"
        ]
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


resource "aws_iam_instance_profile" "server" {
  name = "${var.environment}-${var.colour}-server"
  role = "${aws_iam_role.server.name}"
}

data "aws_ami" "server" {
  most_recent = true

  filter {
    name   = "name"
    values = ["server-${var.server_image_version}-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["${data.aws_caller_identity.current.account_id}"]
}

data "template_file" "server" {
  template = "${file("provision/server.tpl")}"

  vars = {
    aws_region                = "${var.aws_region}"
    environment               = "${var.environment}"
    colour                    = "${var.colour}"
    hosted_zone_name          = "${var.hosted_zone_name}"
    hosted_zone_dns           = "${replace(data.terraform_remote_state.vpc.outputs.platform-vpc-cidr, "0/16", "2")}"
  }
}

resource "aws_instance" "server_a" {
  ami                         = "${data.aws_ami.server.id}"
  instance_type               = "${var.instance_type}"
  subnet_id                   = "${data.terraform_remote_state.subnets.outputs.platform-private-subnet-a-id}"
  private_ip                  = "${replace(data.terraform_remote_state.subnets.outputs.platform-private-subnet-a-cidr, "0/24", "150")}"
  vpc_security_group_ids      = ["${aws_security_group.server.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.server.id}"
  user_data                   = "${data.template_file.server.rendered}"
  associate_public_ip_address = "false"
  key_name                    = "${var.environment}-${var.colour}-${var.key_name}"

  root_block_device {
    volume_type = "${var.volume_type}"
    volume_size = "${var.volume_size}"
  }

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-server-a"
  }
}

/*
resource "aws_instance" "server_b" {
  ami                         = "${data.aws_ami.server.id}"
  instance_type               = "${var.instance_type}"
  subnet_id                   = "${data.terraform_remote_state.subnets.outputs.platform-private-subnet-b-id}"
  private_ip                  = "${replace(data.terraform_remote_state.subnets.outputs.platform-private-subnet-b-cidr, "0/24", "150")}"
  vpc_security_group_ids      = ["${aws_security_group.server.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.server.id}"
  user_data                   = "${data.template_file.server.rendered}"
  associate_public_ip_address = "false"
  key_name                    = "${var.environment}-${var.colour}-${var.key_name}"

  root_block_device {
    volume_type = "${var.volume_type}"
    volume_size = "${var.volume_size}"
  }

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-server-b"
  }
}

resource "aws_instance" "server_c" {
  ami                         = "${data.aws_ami.server.id}"
  instance_type               = "${var.instance_type}"
  subnet_id                   = "${data.terraform_remote_state.subnets.outputs.platform-private-subnet-c-id}"
  private_ip                  = "${replace(data.terraform_remote_state.subnets.outputs.platform-private-subnet-c-cidr, "0/24", "150")}"
  vpc_security_group_ids      = ["${aws_security_group.server.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.server.id}"
  user_data                   = "${data.template_file.server.rendered}"
  associate_public_ip_address = "false"
  key_name                    = "${var.environment}-${var.colour}-${var.key_name}"

  root_block_device {
    volume_type = "${var.volume_type}"
    volume_size = "${var.volume_size}"
  }

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-server-c"
  }
}
*/

# resource "aws_launch_configuration" "server_launch_configuration" {
#   name_prefix                 = "${var.environment}-${var.colour}-server-"
#   image_id                    = "${data.aws_ami.server.id}"
#   instance_type               = "${var.instance_type}"
#   security_groups             = ["${aws_security_group.server.id}"]
#   iam_instance_profile        = "${aws_iam_instance_profile.server.id}"
#   user_data                   = "${data.template_file.server.rendered}"
#   associate_public_ip_address = "false"
#
#   lifecycle {
#     create_before_destroy = true
#   }
# }
#
# resource "aws_autoscaling_group" "server_asg" {
#   name                      = "${var.environment}-${var.colour}-server-"
#   max_size                  = 12
#   min_size                  = 0
#   health_check_grace_period = 300
#   health_check_type         = "EC2"
#   desired_capacity          = 0
#   force_delete              = true
#   launch_configuration      = "${aws_launch_configuration.server_launch_configuration.name}"
#   vpc_zone_identifier       = [
#     "${data.terraform_remote_state.subnets.outputs.platform-private-subnet-a-id}",
#     "${data.terraform_remote_state.subnets.outputs.platform-private-subnet-b-id}",
#     "${data.terraform_remote_state.subnets.outputs.platform-private-subnet-c-id}"
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
#     value                   = "${var.environment}-${var.colour}-server-"
#     propagate_at_launch     = true
#   }
#
#   timeouts {
#     delete = "15m"
#   }
# }

resource "aws_route53_record" "server" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-server.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${aws_instance.server_a.private_ip}"
  ]

  #records = [
    #"${aws_instance.server_a.private_ip}",
    #"${aws_instance.server_b.private_ip}",
    #"${aws_instance.server_c.private_ip}"
  #]
}

resource "aws_route53_record" "server_a" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-server-a.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${aws_instance.server_a.private_ip}"
  ]
}

/*
resource "aws_route53_record" "server_b" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-server-b.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${aws_instance.server_b.private_ip}"
  ]
}

resource "aws_route53_record" "server_c" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-server-c.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [
    "${aws_instance.server_c.private_ip}"
  ]
}
*/
