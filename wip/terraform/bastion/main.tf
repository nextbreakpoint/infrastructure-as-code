##############################################################################
# Providers
##############################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region  = "${var.aws_region}"
}

##############################################################################
# Resources
##############################################################################

resource "aws_security_group" "bastion" {
  name        = "${var.environment}-${var.colour}-bastion"
  description = "Bastion security group"
  vpc_id      = "${data.terraform_remote_state.vpc.outputs.bastion-vpc-id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    self        = false
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
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

resource "aws_iam_role" "bastion" {
  name = "${var.environment}-${var.colour}-bastion"

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
        "Service": "route53.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "bastion" {
  name = "${var.environment}-${var.colour}-bastion"
  role = "${aws_iam_role.bastion.id}"

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
            "ssm:UpdateInstanceInformation",
            "ssm:ListAssociations",
            "ssm:ListInstanceAssociations"
        ],
        "Effect": "Allow",
        "Resource": "*"
    },
    {
        "Action": [
            "route53:ChangeResourceRecordSets",
            "route53:ListResourceRecordSets",
            "route53:GetHostedZone"
        ],
        "Effect": "Allow",
        "Resource": [
            "arn:aws:route53:::hostedzone/${var.hosted_zone_id}"
        ]
    },
    {
        "Action": [
            "route53:ListHostedZones",
            "route53:ListHostedZonesByName"
        ],
        "Effect": "Allow",
        "Resource": [
            "*"
        ]
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.environment}-${var.colour}-bastion"
  role = "${aws_iam_role.bastion.name}"
}

data "template_file" "bastion" {
  template = "${file("provision/bastion.tpl")}"

  vars = {
    environment                = "${var.environment}"
    colour                     = "${var.colour}"
    bastion_dns                = "${var.environment}-${var.colour}-bastion.${var.hosted_zone_name}"
    hosted_zone_name           = "${var.hosted_zone_name}"
    hosted_zone_id             = "${var.hosted_zone_id}"
  }
}

data "aws_ami" "bastion" {
   most_recent = true

   filter {
     name = "name"
     values = ["*ubuntu-jammy-22.04-amd64-server-*"]
   }

   filter {
     name = "virtualization-type"
     values = ["hvm"]
   }

   filter {
     name = "root-device-type"
     values = ["ebs"]
   }

   owners = ["099720109477"]
}

module "bastion_a" {
  source = "./bastion"

  count                 = "${var.bastion == true ? 1 : 0}"
  environment           = "${var.environment}"
  colour                = "${var.colour}"
  name                  = "${var.environment}-${var.colour}-bastion-a"
  #ami                  = "${lookup(var.amazon_nat_ami, var.aws_region)}"
  ami                   = "${data.aws_ami.bastion.id}"
  volume_type           = "${var.volume_type}"
  volume_size           = "${var.volume_size}"
  instance_profile      = "${aws_iam_instance_profile.bastion.id}"
  instance_type         = "${var.instance_type}"
  key_name              = "${var.environment}-${var.colour}-${var.key_name}"
  security_groups       = "${aws_security_group.bastion.id}"
  subnet_id             = "${data.terraform_remote_state.subnets.outputs.bastion-public-subnet-a-id}"
  user_data             = "${data.template_file.bastion.rendered}"
}

# module "bastion_b" {
#   source = "./bastion"
#
  # count                 = "${var.bastion == true ? 1 : 0}"
  # environment           = "${var.environment}"
  # colour                = "${var.colour}"
  # name                  = "${var.environment}-${var.colour}-bastion-b"
  # #ami                  = "${lookup(var.amazon_nat_ami, var.aws_region)}"
  # ami                   = "${data.aws_ami.bastion.id}"
  # volume_type           = "${var.volume_type}"
  # volume_size           = "${var.volume_size}"
  # instance_profile      = "${aws_iam_instance_profile.bastion.id}"
  # instance_type         = "${var.instance_type}"
  # key_name              = "${var.environment}-${var.colour}-${var.key_name}"
  # security_groups       = "${aws_security_group.bastion.id}"
  # subnet_id             = "${data.terraform_remote_state.subnets.outputs.bastion-public-subnet-b-id}"
  # user_data             = "${data.template_file.bastion.rendered}"
# }

# module "bastion_c" {
#   source = "./bastion"
#
  # count                 = "${var.bastion == true ? 1 : 0}"
  # environment           = "${var.environment}"
  # colour                = "${var.colour}"
  # name                  = "${var.environment}-${var.colour}-bastion-c"
  # #ami                  = "${lookup(var.amazon_nat_ami, var.aws_region)}"
  # ami                   = "${data.aws_ami.bastion.id}"
  # volume_type           = "${var.volume_type}"
  # volume_size           = "${var.volume_size}"
  # instance_profile      = "${aws_iam_instance_profile.bastion.id}"
  # instance_type         = "${var.instance_type}"
  # key_name              = "${var.environment}-${var.colour}-${var.key_name}"
  # security_groups       = "${aws_security_group.bastion.id}"
  # subnet_id             = "${data.terraform_remote_state.subnets.outputs.bastion-public-subnet-c-id}"
  # user_data             = "${data.template_file.bastion.rendered}"
# }

resource "aws_route53_record" "bastion" {
  count   = "${var.bastion == true ? 1 : 0}"
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-bastion.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "300"
  records = [
    "${module.bastion_a[0].public-ips}"
  ]
  # records = [
  #   "${module.bastion_a.public-ips}",
  #   "${module.bastion_b.public-ips}",
  #   "${module.bastion_c.public-ips}"
  # ]
}
