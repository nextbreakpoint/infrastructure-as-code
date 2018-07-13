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

provider "local" {
  version = "~> 0.1"
}

##############################################################################
# Resources
##############################################################################

resource "aws_security_group" "openvpn" {
  name        = "${var.environment}-${var.colour}-openvpn"
  description = "OpenVPN security group"
  vpc_id      = "${data.terraform_remote_state.vpc.openvpn-vpc-id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.aws_bastion_vpc_cidr}"]
  }

  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["${data.terraform_remote_state.vpc.network-vpc-cidr}","${data.terraform_remote_state.vpc.bastion-vpc-cidr}"]
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

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
  }
}

resource "aws_iam_role" "openvpn" {
  name = "${var.environment}-${var.colour}-openvpn"

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

resource "aws_iam_role_policy" "openvpn" {
  name = "${var.environment}-${var.colour}-openvpn"
  role = "${aws_iam_role.openvpn.id}"

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


# {
#     "Action": [
#         "ssm:UpdateInstanceInformation",
#         "ssm:ListAssociations",
#         "ssm:ListInstanceAssociations"
#     ],
#     "Effect": "Allow",
#     "Resource": "*"
# },
# {
#     "Action": [
#         "route53:ChangeResourceRecordSets",
#         "route53:GetHostedZone",
#         "route53:ListResourceRecordSets"
#     ],
#     "Effect": "Allow",
#     "Resource": [
#         "arn:aws:route53:::${var.hosted_zone_name}/<ZoneID>"
#     ]
# },
# {
#     "Action": [
#         "route53:ListHostedZones",
#         "route53:ListHostedZonesByName"
#     ],
#     "Effect": "Allow",
#     "Resource": [
#         "*"
#     ]
# }


resource "aws_iam_instance_profile" "openvpn" {
  name = "${var.environment}-${var.colour}-openvpn"
  role = "${aws_iam_role.openvpn.name}"
}

resource "aws_route_table" "openvpn" {
  vpc_id = "${data.terraform_remote_state.vpc.openvpn-vpc-id}"

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.network-to-openvpn-peering-connection-id}"
    cidr_block                = "${data.terraform_remote_state.vpc.network-vpc-cidr}"
  }

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.bastion-to-openvpn-peering-connection-id}"
    cidr_block                = "${data.terraform_remote_state.vpc.bastion-vpc-cidr}"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${data.terraform_remote_state.vpc.openvpn-internet-gateway-id}"
  }

  tags {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-openvpn"
  }
}

resource "aws_subnet" "openvpn_a" {
  vpc_id                  = "${data.terraform_remote_state.vpc.openvpn-vpc-id}"
  availability_zone       = "${format("%s%s", var.aws_region, "a")}"
  cidr_block              = "${var.aws_openvpn_subnet_cidr_a}"
  map_public_ip_on_launch = true

  tags {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-openvpn-a"
  }
}

resource "aws_subnet" "openvpn_b" {
  vpc_id                  = "${data.terraform_remote_state.vpc.openvpn-vpc-id}"
  availability_zone       = "${format("%s%s", var.aws_region, "b")}"
  cidr_block              = "${var.aws_openvpn_subnet_cidr_b}"
  map_public_ip_on_launch = true

  tags {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-openvpn-b"
  }
}

resource "aws_subnet" "openvpn_c" {
  vpc_id                  = "${data.terraform_remote_state.vpc.openvpn-vpc-id}"
  availability_zone       = "${format("%s%s", var.aws_region, "c")}"
  cidr_block              = "${var.aws_openvpn_subnet_cidr_c}"
  map_public_ip_on_launch = true

  tags {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-openvpn-c"
  }
}

resource "aws_route_table_association" "openvpn_a" {
  subnet_id      = "${aws_subnet.openvpn_a.id}"
  route_table_id = "${aws_route_table.openvpn.id}"
}

resource "aws_route_table_association" "openvpn_b" {
  subnet_id      = "${aws_subnet.openvpn_b.id}"
  route_table_id = "${aws_route_table.openvpn.id}"
}

resource "aws_route_table_association" "openvpn_c" {
  subnet_id      = "${aws_subnet.openvpn_c.id}"
  route_table_id = "${aws_route_table.openvpn.id}"
}

data "aws_ami" "openvpn" {
  most_recent = true

  filter {
    name   = "name"
    values = ["openvpn-${var.environment}-${var.colour}-${var.base_version}-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["${var.account_id}"]
}

data "template_file" "openvpn" {
  template = "${file("provision/openvpn.tpl")}"

  vars {
    aws_region                 = "${var.aws_region}"
    environment                = "${var.environment}"
    colour                     = "${var.colour}"
    bucket_name                = "${var.secrets_bucket_name}"
    openvpn_cidr               = "${var.openvpn_cidr}"
    openvpn_subnet             = "${replace(var.openvpn_cidr, "0/16", "0")}"
    hosted_zone_name           = "${var.hosted_zone_name}"
    aws_openvpn_subnet         = "${replace(var.aws_openvpn_vpc_cidr, "0/16", "0")}"
    aws_network_subnet         = "${replace(var.aws_network_vpc_cidr, "0/16", "0")}"
    aws_bastion_subnet         = "${replace(var.aws_bastion_vpc_cidr, "0/16", "0")}"
    aws_network_dns            = "${replace(var.aws_network_vpc_cidr, "0/16", "2")}"
  }
}

resource "aws_instance" "openvpn_a" {
  ami                         = "${data.aws_ami.openvpn.id}"
  instance_type               = "${var.openvpn_instance_type}"
  subnet_id                   = "${aws_subnet.openvpn_a.id}"
  vpc_security_group_ids      = ["${aws_security_group.openvpn.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.openvpn.id}"
  user_data                   = "${data.template_file.openvpn.rendered}"
  associate_public_ip_address = "true"
  source_dest_check           = false
  key_name                    = "${var.environment}-${var.colour}-${var.key_name}"

  tags {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-openvpn-a"
  }
}

# resource "aws_instance" "openvpn_b" {
#   ami                         = "${data.aws_ami.openvpn.id}"
#   instance_type               = "${var.openvpn_instance_type}"
#   subnet_id                   = "${aws_subnet.openvpn_b.id}"
#   vpc_security_group_ids      = ["${aws_security_group.openvpn.id}"]
#   iam_instance_profile        = "${aws_iam_instance_profile.openvpn.id}"
#   user_data                   = "${data.template_file.openvpn.rendered}"
#   associate_public_ip_address = "true"
#   source_dest_check           = false
#   key_name                    = "${var.environment}-${var.colour}-${var.key_name}"
#
#   tags {
#     Environment = "${var.environment}"
#     Colour      = "${var.colour}"
#     Name        = "${var.environment}-${var.colour}-openvpn-b"
#   }
# }

# resource "aws_instance" "openvpn_c" {
#   ami                         = "${data.aws_ami.openvpn.id}"
#   instance_type               = "${var.openvpn_instance_type}"
#   subnet_id                   = "${aws_subnet.openvpn_c.id}"
#   vpc_security_group_ids      = ["${aws_security_group.openvpn.id}"]
#   iam_instance_profile        = "${aws_iam_instance_profile.openvpn.id}"
#   user_data                   = "${data.template_file.openvpn.rendered}"
#   associate_public_ip_address = "true"
#   source_dest_check           = false
#   key_name                    = "${var.environment}-${var.colour}-${var.key_name}"
#
#   tags {
#     Environment = "${var.environment}"
#     Colour      = "${var.colour}"
#     Name        = "${var.environment}-${var.colour}-openvpn-c"
#   }
# }

resource "aws_route53_record" "openvpn" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-openvpn.${var.hosted_zone_name}"
  type    = "A"
  ttl     = 60
  records = ["${aws_instance.openvpn_a.public_ip}"]
  # records = [
  #   "${aws_instance.openvpn_a.public_ip}",
  #   "${aws_instance.openvpn_b.public_ip}",
  #   "${aws_instance.openvpn_c.public_ip}"
  # ]
}

data "template_file" "ca_cert" {
  template = "${file("../../secrets/environments/${var.environment}/${var.colour}/openvpn/ca_cert.pem")}"
}

data "template_file" "client_key" {
  template = "${file("../../secrets/environments/${var.environment}/${var.colour}/openvpn/client_key.pem")}"
}

data "template_file" "client_cert" {
  template = "${file("../../secrets/environments/${var.environment}/${var.colour}/openvpn/client_cert.pem")}"
}

data "template_file" "ta_auth" {
  template = "${file("../../secrets/environments/${var.environment}/${var.colour}/openvpn/ta.pem")}"
}

resource "local_file" "client_config" {
  content = <<EOF
client

proto udp
dev tun

remote ${var.environment}-${var.colour}-openvpn.${var.hosted_zone_name} 1194

resolv-retry infinite

nobind

persist-key
persist-tun

remote-cert-tls server

key-direction 1

cipher AES-128-CBC

auth SHA256

comp-lzo

script-security 3

verb 3

explicit-exit-notify 1

<ca>
${data.template_file.ca_cert.rendered}</ca>
<key>
${data.template_file.client_key.rendered}</key>
<cert>
${data.template_file.client_cert.rendered}</cert>
<tls-auth>
${data.template_file.ta_auth.rendered}</tls-auth>
EOF

  filename = "../../secrets/openvpn/${var.environment}/${var.colour}/openvpn_client.ovpn"
}

resource "local_file" "base_config" {
  content = <<EOF
client

proto udp
dev tun

remote ${var.environment}-${var.colour}-openvpn.${var.hosted_zone_name} 1194

resolv-retry infinite

nobind

persist-key
persist-tun

remote-cert-tls server

key-direction 1

cipher AES-128-CBC

auth SHA256

comp-lzo

script-security 3

verb 3

explicit-exit-notify 1
EOF

  filename = "../../secrets/openvpn/${var.environment}/${var.colour}/openvpn_base.conf"
}
