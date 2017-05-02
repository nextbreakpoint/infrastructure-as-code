##############################################################################
# Provider
##############################################################################

provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
  shared_credentials_file = "${var.aws_shared_credentials_file}"
}

##############################################################################
# Remote state
##############################################################################

data "terraform_remote_state" "vpc" {
    backend = "s3"
    config {
        bucket = "nextbreakpoint-terraform-state"
        region = "${var.aws_region}"
        key = "vpc.tfstate"
    }
}

data "terraform_remote_state" "network" {
    backend = "s3"
    config {
        bucket = "nextbreakpoint-terraform-state"
        region = "${var.aws_region}"
        key = "network.tfstate"
    }
}

##############################################################################
# Cassandra servers
##############################################################################

resource "aws_security_group" "cassandra_server" {
  name = "cassandra server"
  description = "cassandra server security group"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.aws_bastion_vpc_cidr}"]
  }

  ingress {
    from_port = 7000
    to_port = 7001
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 7199
    to_port = 7199
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 9042
    to_port = 9042
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 9142
    to_port = 9142
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 9160
    to_port = 9160
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 8300
    to_port = 8302
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 8300
    to_port = 8302
    protocol = "udp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  egress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

  egress {
    from_port = 7000
    to_port = 7001
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  egress {
    from_port = 7199
    to_port = 7199
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  egress {
    from_port = 9042
    to_port = 9042
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  egress {
    from_port = 9142
    to_port = 9142
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  egress {
    from_port = 9160
    to_port = 9160
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }
  
  egress {
    from_port = 8300
    to_port = 8302
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  egress {
    from_port = 8300
    to_port = 8302
    protocol = "udp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  tags {
    Name = "cassandra server security group"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_iam_instance_profile" "cassandra_node_profile" {
    name = "cassandra_node_profile"
    roles = ["${aws_iam_role.cassandra_node_role.name}"]
}

resource "aws_iam_role" "cassandra_node_role" {
  name = "cassandra_node_role"

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

resource "aws_iam_role_policy" "cassandra_node_role_policy" {
  name = "cassandra_node_role_policy"
  role = "${aws_iam_role.cassandra_node_role.id}"

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

data "template_file" "cassandra_server_user_data_seed" {
  template = "${file("provision/cassandra-seed.tpl")}"

  vars {
    aws_region              = "${var.aws_region}"
    security_groups         = "${aws_security_group.cassandra_server.id}"
    consul_log_file         = "${var.consul_log_file}"
    log_group_name          = "${var.log_group_name}"
    log_stream_name         = "${var.log_stream_name}"
  }
}

resource "aws_instance" "cassandra_server_a1" {
  instance_type = "${var.aws_cassandra_instance_type}"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.cassandra_amis, var.aws_region)}"

  subnet_id = "${data.terraform_remote_state.network.network-private-subnet-a-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.cassandra_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.cassandra_node_profile.id}"

  connection {
    #host = "${element(aws_instance.cassandra_server_a1.*.private_ip, 0)}"
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
        "${data.template_file.cassandra_server_user_data_seed.rendered}"
    ]
  }

  tags {
    Name = "cassandra_server_a1"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "cassandra_server_b1" {
  instance_type = "${var.aws_cassandra_instance_type}"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.cassandra_amis, var.aws_region)}"

  subnet_id = "${data.terraform_remote_state.network.network-private-subnet-b-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.cassandra_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.cassandra_node_profile.id}"

  connection {
    #host = "${element(aws_instance.cassandra_server_b1.*.private_ip, 0)}"
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
        "${data.template_file.cassandra_server_user_data_seed.rendered}"
    ]
  }

  tags {
    Name = "cassandra_server_b1"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "cassandra_server_c1" {
  instance_type = "${var.aws_cassandra_instance_type}"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.cassandra_amis, var.aws_region)}"

  subnet_id = "${data.terraform_remote_state.network.network-private-subnet-c-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.cassandra_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.cassandra_node_profile.id}"

  connection {
    #host = "${element(aws_instance.cassandra_server_c1.*.private_ip, 0)}"
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
        "${data.template_file.cassandra_server_user_data_seed.rendered}"
    ]
  }

  tags {
    Name = "cassandra_server_c1"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "cassandra_server_a2" {
  instance_type = "${var.aws_cassandra_instance_type}"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.cassandra_amis, var.aws_region)}"

  subnet_id = "${data.terraform_remote_state.network.network-private-subnet-a-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.cassandra_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.cassandra_node_profile.id}"

  tags {
    Name = "cassandra_server_a2"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "cassandra_server_b2" {
  instance_type = "${var.aws_cassandra_instance_type}"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.cassandra_amis, var.aws_region)}"

  subnet_id = "${data.terraform_remote_state.network.network-private-subnet-b-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.cassandra_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.cassandra_node_profile.id}"

  tags {
    Name = "cassandra_server_b2"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "cassandra_server_c2" {
  instance_type = "${var.aws_cassandra_instance_type}"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.cassandra_amis, var.aws_region)}"

  subnet_id = "${data.terraform_remote_state.network.network-private-subnet-c-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.cassandra_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.cassandra_node_profile.id}"

  tags {
    Name = "cassandra_server_c2"
    Stream = "${var.stream_tag}"
  }
}

data "template_file" "cassandra_server_user_data_node" {
  template = "${file("provision/cassandra-node.tpl")}"

  vars {
    aws_region              = "${var.aws_region}"
    security_groups         = "${aws_security_group.cassandra_server.id}"
    consul_log_file         = "${var.consul_log_file}"
    log_group_name          = "${var.log_group_name}"
    log_stream_name         = "${var.log_stream_name}"
    cassandra_seeds         = "${aws_instance.cassandra_server_a1.private_ip},${aws_instance.cassandra_server_b1.private_ip},${aws_instance.cassandra_server_c1.private_ip}"
  }
}

resource "null_resource" "cassandra_server_a2" {
  #depends_on = ["aws_volume_attachment.cassandra_volume_attachment_a"]
  depends_on = ["aws_instance.cassandra_server_a1","aws_instance.cassandra_server_b1","aws_instance.cassandra_server_c1"]

  triggers {
    cluster_instance_ids = "${join(",", aws_instance.cassandra_server_a2.*.id)}"
  }

  connection {
    host = "${element(aws_instance.cassandra_server_a2.*.private_ip, 0)}"
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
        "sleep 60",
        "${data.template_file.cassandra_server_user_data_node.rendered}"
    ]
  }
}

resource "null_resource" "cassandra_server_b2" {
  #depends_on = ["aws_volume_attachment.cassandra_volume_attachment_b"]
  depends_on = ["aws_instance.cassandra_server_a1","aws_instance.cassandra_server_b1","aws_instance.cassandra_server_c1"]

  triggers {
    cluster_instance_ids = "${join(",", aws_instance.cassandra_server_b2.*.id)}"
  }

  connection {
    host = "${element(aws_instance.cassandra_server_b2.*.private_ip, 0)}"
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
        "sleep 120",
        "${data.template_file.cassandra_server_user_data_node.rendered}"
    ]
  }
}

resource "null_resource" "cassandra_server_c2" {
  #depends_on = ["aws_volume_attachment.cassandra_volume_attachment_c"]
  depends_on = ["aws_instance.cassandra_server_a1","aws_instance.cassandra_server_b1","aws_instance.cassandra_server_c1"]

  triggers {
    cluster_instance_ids = "${join(",", aws_instance.cassandra_server_c2.*.id)}"
  }

  connection {
    host = "${element(aws_instance.cassandra_server_c2.*.private_ip, 0)}"
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
        "sleep 180",
        "${data.template_file.cassandra_server_user_data_node.rendered}"
    ]
  }
}
