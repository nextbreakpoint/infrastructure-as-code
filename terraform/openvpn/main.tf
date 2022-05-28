data "aws_caller_identity" "current" {}

resource "aws_security_group" "openvpn" {
  name        = "${var.environment}-${var.colour}-openvpn"
  description = "OpenVPN security group"
  vpc_id      = "${data.terraform_remote_state.vpc.outputs.openvpn-vpc-id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.outputs.bastion-vpc-cidr}"]
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
    cidr_blocks = ["${data.terraform_remote_state.vpc.outputs.platform-vpc-cidr}","${data.terraform_remote_state.vpc.outputs.bastion-vpc-cidr}"]
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

  tags = {
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
          "s3:*"
        ],
        "Effect": "Allow",
        "Resource": [
          "arn:aws:s3:::${var.openvpn_bucket_name}",
          "arn:aws:s3:::${var.openvpn_bucket_name}/*"
        ]
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
#     "Resource": "*"
# }


resource "aws_iam_instance_profile" "openvpn" {
  name = "${var.environment}-${var.colour}-openvpn"
  role = "${aws_iam_role.openvpn.name}"
}

data "aws_ami" "openvpn" {
  most_recent = true

  filter {
    name   = "name"
    values = ["openvpn-${var.openvpn_image_version}-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["${data.aws_caller_identity.current.account_id}"]
}

data "template_file" "openvpn" {
  template = "${file("provision/openvpn.tpl")}"

  vars = {
    environment                = "${var.environment}"
    colour                     = "${var.colour}"
    bucket_name                = "${var.openvpn_bucket_name}"
    key_password               = "${var.openvpn_key_password}"
    keystore_password          = "${var.openvpn_keystore_password}"
    truststore_password        = "${var.openvpn_truststore_password}"
    openvpn_dns                = "${var.environment}-${var.colour}-openvpn.${var.hosted_zone_name}"
    openvpn_cidr               = "${var.openvpn_cidr}"
    openvpn_subnet             = "${replace(var.openvpn_cidr, "0/16", "0")}"
    hosted_zone_name           = "${var.hosted_zone_name}"
    hosted_zone_id             = "${var.hosted_zone_id}"
    aws_openvpn_subnet         = "${replace(data.terraform_remote_state.vpc.outputs.openvpn-vpc-cidr, "0/16", "0")}"
    aws_platform_subnet        = "${replace(data.terraform_remote_state.vpc.outputs.platform-vpc-cidr, "0/16", "0")}"
    aws_bastion_subnet         = "${replace(data.terraform_remote_state.vpc.outputs.bastion-vpc-cidr, "0/16", "0")}"
    aws_platform_dns           = "${replace(data.terraform_remote_state.vpc.outputs.platform-vpc-cidr, "0/16", "2")}"
  }
}

resource "aws_instance" "openvpn_a" {
  count                       = "${var.openvpn == true ? 1 : 0}"
  ami                         = "${data.aws_ami.openvpn.id}"
  instance_type               = "${var.instance_type}"
  subnet_id                   = "${data.terraform_remote_state.subnets.outputs.openvpn-public-subnet-a-id}"
  vpc_security_group_ids      = ["${aws_security_group.openvpn.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.openvpn.id}"
  user_data                   = "${data.template_file.openvpn.rendered}"
  associate_public_ip_address = "true"
  source_dest_check           = false
  key_name                    = "${var.environment}-${var.colour}-${var.key_name}"

  root_block_device {
    volume_type = "${var.volume_type}"
    volume_size = "${var.volume_size}"
  }

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-openvpn-a"
  }
}

# resource "aws_instance" "openvpn_b" {
#   count                       = "${var.openvpn == true ? 1 : 0}"
#   ami                         = "${data.aws_ami.openvpn.id}"
#   instance_type               = "${var.instance_type}"
#   subnet_id                   = "${data.terraform_remote_state.subnets.outputs.openvpn-public-subnet-b-id}"
#   vpc_security_group_ids      = ["${aws_security_group.openvpn.id}"]
#   iam_instance_profile        = "${aws_iam_instance_profile.openvpn.id}"
#   user_data                   = "${data.template_file.openvpn.rendered}"
#   associate_public_ip_address = "true"
#   source_dest_check           = false
#   key_name                    = "${var.environment}-${var.colour}-${var.key_name}"
#
#   root_block_device {
#     volume_type = "${var.volume_type}"
#     volume_size = "${var.volume_size}"
#   }
#
#   tags = {
#     Environment = "${var.environment}"
#     Colour      = "${var.colour}"
#     Name        = "${var.environment}-${var.colour}-openvpn-b"
#   }
# }

resource "aws_route53_record" "openvpn" {
  count   = "${var.openvpn == true ? 1 : 0}"
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.environment}-${var.colour}-openvpn.${var.hosted_zone_name}"
  type    = "A"
  ttl     = 300
  records = [
    "${aws_instance.openvpn_a[0].public_ip}"
  ]
  # records = [
  #   "${aws_instance.openvpn_a[0].public_ip}",
  #   "${aws_instance.openvpn_b[0].public_ip}"
  # ]
}

/*
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

  filename = "../../secrets/generated/${var.environment}/${var.colour}/openvpn_base.conf"
}
*/
