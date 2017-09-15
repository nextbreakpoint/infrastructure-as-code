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

provider "null" {
  version = "~> 0.1"
}

##############################################################################
# Remote state
##############################################################################

terraform {
  backend "s3" {
    bucket = "nextbreakpoint-terraform-state"
    region = "eu-west-1"
    key = "zookeeper.tfstate"
  }
}

data "terraform_remote_state" "vpc" {
    backend = "s3"
    config {
        bucket = "nextbreakpoint-terraform-state"
        region = "${var.aws_region}"
        key = "vpc.tfstate"
    }
}

##############################################################################
# ZooKeeper servers
##############################################################################

resource "aws_security_group" "zookeeper_server" {
  name = "zookeeper-security-group"
  description = "Zookeeper security group"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.aws_bastion_vpc_cidr}"]
  }

  ingress {
    from_port = 2181
    to_port = 2181
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 2888
    to_port = 2888
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 3888
    to_port = 3888
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
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

resource "aws_iam_instance_profile" "zookeeper_server_profile" {
    name = "zookeeper-server-profile"
    role = "${aws_iam_role.zookeeper_server_role.name}"
}

resource "aws_iam_role" "zookeeper_server_role" {
  name = "zookeeper-server-role"

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

resource "aws_iam_role_policy" "zookeeper_server_role_policy" {
  name = "zookeeper-server-role-policy"
  role = "${aws_iam_role.zookeeper_server_role.id}"

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
    }
  ]
}
EOF
}

data "aws_ami" "zookeeper" {
  most_recent = true

  filter {
    name = "name"
    values = ["zookeeper-${var.base_version}-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["${var.account_id}"]
}

resource "aws_instance" "zookeeper_server_a" {
  instance_type = "${var.zookeeper_instance_type}"

  ami = "${data.aws_ami.zookeeper.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-a-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.zookeeper_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.zookeeper_server_profile.name}"

  tags {
    Name = "zookeeper-server-a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "zookeeper_server_b" {
  instance_type = "${var.zookeeper_instance_type}"

  ami = "${data.aws_ami.zookeeper.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-b-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.zookeeper_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.zookeeper_server_profile.name}"

  tags {
    Name = "zookeeper-server-b"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "zookeeper_server_c" {
  instance_type = "${var.zookeeper_instance_type}"

  ami = "${data.aws_ami.zookeeper.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-c-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.zookeeper_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.zookeeper_server_profile.name}"

  tags {
    Name = "zookeeper-server-c"
    Stream = "${var.stream_tag}"
  }
}

data "template_file" "zookeeper_server_user_data" {
  template = "${file("provision/zookeeper.tpl")}"

  vars {
    aws_region              = "${var.aws_region}"
    security_groups         = "${aws_security_group.zookeeper_server.id}"
    consul_log_file         = "${var.consul_log_file}"
    log_group_name          = "${var.log_group_name}"
    log_stream_name         = "${var.log_stream_name}"
    hosted_zone_name        = "${var.hosted_zone_name}"
    zookeeper_nodes         = "${aws_instance.zookeeper_server_a.private_ip},${aws_instance.zookeeper_server_b.private_ip},${aws_instance.zookeeper_server_c.private_ip}"
  }
}

resource "null_resource" "zookeeper_server_a" {
  #depends_on = ["aws_volume_attachment.zookeeper_volume_attachment_a"]

  triggers {
    cluster_instance_ids = "${join(",", aws_instance.zookeeper_server_a.*.id)}"
  }

  connection {
    host = "${element(aws_instance.zookeeper_server_a.*.private_ip, 0)}"
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
    bastion_user = "ec2-user"
    bastion_host = "bastion.${var.public_hosted_zone_name}"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 1 >/tmp/myid",
      "sudo mv /tmp/myid /var/lib/zookeeper/myid"
    ]
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.zookeeper_server_user_data.rendered}"
  }
}

resource "null_resource" "zookeeper_server_b" {
  #depends_on = ["aws_volume_attachment.zookeeper_volume_attachment_b"]

  triggers {
    cluster_instance_ids = "${join(",", aws_instance.zookeeper_server_b.*.id)}"
  }

  connection {
    host = "${element(aws_instance.zookeeper_server_b.*.private_ip, 0)}"
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
    bastion_user = "ec2-user"
    bastion_host = "bastion.${var.public_hosted_zone_name}"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 2 >/tmp/myid",
      "sudo mv /tmp/myid /var/lib/zookeeper/myid"
    ]
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.zookeeper_server_user_data.rendered}"
  }
}

resource "null_resource" "zookeeper_server_c" {
  #depends_on = ["aws_volume_attachment.zookeeper_volume_attachment_c"]

  triggers {
    cluster_instance_ids = "${join(",", aws_instance.zookeeper_server_c.*.id)}"
  }

  connection {
    host = "${element(aws_instance.zookeeper_server_c.*.private_ip, 0)}"
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
    bastion_user = "ec2-user"
    bastion_host = "bastion.${var.public_hosted_zone_name}"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 3 >/tmp/myid",
      "sudo mv /tmp/myid /var/lib/zookeeper/myid"
    ]
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.zookeeper_server_user_data.rendered}"
  }
}

##############################################################################
# Route 53
##############################################################################

resource "aws_route53_record" "zookeeper" {
   zone_id = "${data.terraform_remote_state.vpc.hosted-zone-id}"
   name = "zookeeper.${var.hosted_zone_name}"
   type = "A"
   ttl = "300"

   records = [
     "${aws_instance.zookeeper_server_a.private_ip}",
     "${aws_instance.zookeeper_server_b.private_ip}",
     "${aws_instance.zookeeper_server_c.private_ip}"
   ]
}
