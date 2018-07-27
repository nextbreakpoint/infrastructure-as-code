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

resource "aws_security_group" "bastion" {
  name        = "${var.environment}-${var.colour}-bastion"
  description = "Bastion security group"
  vpc_id      = "${data.terraform_remote_state.vpc.bastion-vpc-id}"

  ingress = {
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
    cidr_blocks = ["${data.terraform_remote_state.vpc.network-vpc-cidr}","${data.terraform_remote_state.vpc.openvpn-vpc-cidr}"]
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

resource "aws_route_table" "bastion" {
  vpc_id = "${data.terraform_remote_state.vpc.bastion-vpc-id}"

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.network-to-bastion-peering-connection-id}"
    cidr_block                = "${data.terraform_remote_state.vpc.network-vpc-cidr}"
  }

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.bastion-to-openvpn-peering-connection-id}"
    cidr_block                = "${data.terraform_remote_state.vpc.openvpn-vpc-cidr}"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${data.terraform_remote_state.vpc.bastion-internet-gateway-id}"
  }

  tags {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-bastion"
  }
}

resource "aws_subnet" "bastion_a" {
  vpc_id                  = "${data.terraform_remote_state.vpc.bastion-vpc-id}"
  availability_zone       = "${format("%s%s", var.aws_region, "a")}"
  cidr_block              = "${var.aws_bastion_subnet_cidr_a}"
  map_public_ip_on_launch = true

  tags {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-bastion-a"
  }
}

resource "aws_subnet" "bastion_b" {
  vpc_id                  = "${data.terraform_remote_state.vpc.bastion-vpc-id}"
  availability_zone       = "${format("%s%s", var.aws_region, "b")}"
  cidr_block              = "${var.aws_bastion_subnet_cidr_b}"
  map_public_ip_on_launch = true

  tags {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-bastion-b"
  }
}

resource "aws_subnet" "bastion_c" {
  vpc_id                  = "${data.terraform_remote_state.vpc.bastion-vpc-id}"
  availability_zone       = "${format("%s%s", var.aws_region, "c")}"
  cidr_block              = "${var.aws_bastion_subnet_cidr_c}"
  map_public_ip_on_launch = true

  tags {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-bastion-c"
  }
}

resource "aws_route_table_association" "bastion_a" {
  subnet_id      = "${aws_subnet.bastion_a.id}"
  route_table_id = "${aws_route_table.bastion.id}"
}

resource "aws_route_table_association" "bastion_b" {
  subnet_id      = "${aws_subnet.bastion_b.id}"
  route_table_id = "${aws_route_table.bastion.id}"
}

resource "aws_route_table_association" "bastion_c" {
  subnet_id      = "${aws_subnet.bastion_c.id}"
  route_table_id = "${aws_route_table.bastion.id}"
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
      "Effect": "Allow",
      "Sid": ""
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
            "route53:GetHostedZone",
            "route53:ListResourceRecordSets"
        ],
        "Effect": "Allow",
        "Resource": [
            "arn:aws:route53:::${var.hosted_zone_name}/<ZoneID>"
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
}

# data "aws_ami" "bastion" {
#   most_recent = true
#
#   filter {
#     name = "name"
#     values = ["*ubuntu-xenial-16.04-amd64-server-*"]
#   }
#
#   filter {
#     name = "virtualization-type"
#     values = ["hvm"]
#   }
#
#   filter {
#     name = "root-device-type"
#     values = ["ebs"]
#   }
#
#   owners = ["099720109477"]
# }

module "bastion_a" {
  source = "./bastion"

  count                 = "${var.bastion_count}"
  environment           = "${var.environment}"
  colour                = "${var.colour}"
  name                  = "${var.environment}-${var.colour}-bastion-a"
  ami                   = "${lookup(var.amazon_nat_ami, var.aws_region)}"
  # ami                 = "${data.aws_ami.bastion.id}"
  instance_profile      = "${aws_iam_instance_profile.bastion.id}"
  instance_type         = "${var.bastion_instance_type}"
  key_name              = "${var.environment}-${var.colour}-${var.key_name}"
  security_groups       = "${aws_security_group.bastion.id}"
  subnet_id             = "${aws_subnet.bastion_a.id}"
  user_data             = "${data.template_file.bastion.rendered}"
}

# module "bastion_b" {
#   source = "./bastion"
#
  # count                 = "${var.bastion_count}"
  # environment           = "${var.environment}"
  # colour                = "${var.colour}"
  # name                  = "${var.environment}-${var.colour}-bastion-b"
  # ami                   = "${lookup(var.amazon_nat_ami, var.aws_region)}"
  # # ami                 = "${data.aws_ami.bastion.id}"
  # instance_profile      = "${aws_iam_instance_profile.bastion.id}"
  # instance_type         = "${var.bastion_instance_type}"
  # key_name              = "${var.environment}-${var.colour}-${var.key_name}"
  # security_groups       = "${aws_security_group.bastion.id}"
  # subnet_id             = "${aws_subnet.bastion_b.id}"
  # user_data             = "${data.template_file.bastion.rendered}"
# }

# module "bastion_c" {
#   source = "./bastion"
#
  # count                 = "${var.bastion_count}"
  # environment           = "${var.environment}"
  # colour                = "${var.colour}"
  # name                  = "${var.environment}-${var.colour}-bastion-c"
  # ami                   = "${lookup(var.amazon_nat_ami, var.aws_region)}"
  # # ami                 = "${data.aws_ami.bastion.id}"
  # instance_profile      = "${aws_iam_instance_profile.bastion.id}"
  # instance_type         = "${var.bastion_instance_type}"
  # key_name              = "${var.environment}-${var.colour}-${var.key_name}"
  # security_groups       = "${aws_security_group.bastion.id}"
  # subnet_id             = "${aws_subnet.bastion_c.id}"
  # user_data             = "${data.template_file.bastion.rendered}"
# }

resource "aws_route53_record" "bastion" {
  count   = "${var.bastion_count}"
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-bastion.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "60"
  records = ["${module.bastion_a.public-ips}"]
  # records = [
  #   "${module.bastion_a.public-ips}",
  #   "${module.bastion_b.public-ips}",
  #   "${module.bastion_c.public-ips}"
  # ]
}
