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

terraform {
  backend "s3" {
    bucket = "nextbreakpoint-terraform-state"
    region = "eu-west-1"
    key = "maintenance.tfstate"
  }
}

##############################################################################
# Maintenance servers
##############################################################################

resource "aws_security_group" "maintenance_server" {
  name = "maintenance-security-group"
  description = "maintenance security group"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  tags {
    Stream = "${var.stream_tag}"
  }
}

resource "aws_iam_instance_profile" "maintenance_server_profile" {
    name = "maintenance-server-profile"
    role = "${aws_iam_role.maintenance_server_role.name}"
}

resource "aws_iam_role" "maintenance_server_role" {
  name = "maintenance-server-role"

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

resource "aws_iam_role_policy" "maintenance_server_role_policy" {
  name = "maintenance-server-role-policy"
  role = "${aws_iam_role.maintenance_server_role.id}"

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

resource "aws_instance" "maintenance_server_a" {
  instance_type = "t2.micro"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.amazon_ubuntu_amis, var.aws_region)}"

  subnet_id = "${data.terraform_remote_state.vpc.network-public-subnet-a-id}"
  associate_public_ip_address = "true"
  security_groups = ["${aws_security_group.maintenance_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.maintenance_server_profile.id}"

  connection {
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
  }

  tags {
    Name = "maintenance-server-a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "maintenance_server_b" {
  instance_type = "t2.micro"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.amazon_ubuntu_amis, var.aws_region)}"

  subnet_id = "${data.terraform_remote_state.vpc.network-public-subnet-b-id}"
  associate_public_ip_address = "true"
  security_groups = ["${aws_security_group.maintenance_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.maintenance_server_profile.id}"

  connection {
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
  }

  tags {
    Name = "maintenance-server-b"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_volume_attachment" "elasticsearch_volume_attachment_a" {
  device_name = "${var.elasticsearch_device_name}"
  volume_id = "${data.terraform_remote_state.volumes.elasticsearch-volume-a-id}"
  instance_id = "${aws_instance.maintenance_server_a.id}"
  skip_destroy = true
}

resource "aws_volume_attachment" "pipeline_volume_attachment_a" {
  device_name = "${var.pipeline_device_name}"
  volume_id = "${data.terraform_remote_state.volumes.pipeline-volume-a-id}"
  instance_id = "${aws_instance.maintenance_server_a.id}"
  skip_destroy = true
}

resource "aws_volume_attachment" "elasticsearch_volume_attachment_b" {
  device_name = "${var.elasticsearch_device_name}"
  volume_id = "${data.terraform_remote_state.volumes.elasticsearch-volume-b-id}"
  instance_id = "${aws_instance.maintenance_server_b.id}"
  skip_destroy = true
}

data "template_file" "create_elasticsearch_partition" {
  template = "${file("provision/create_single_partition.tpl")}"

  vars {
    device_name               = "${var.elasticsearch_device_name}"
  }
}

data "template_file" "create_pipeline_partition" {
  template = "${file("provision/create_single_partition.tpl")}"

  vars {
    device_name               = "${var.pipeline_device_name}"
  }
}

data "template_file" "copy_pipeline_data" {
  template = "${file("provision/copy_mysql_data.tpl")}"

  vars {
    device_name               = "${var.pipeline_device_name}"
  }
}

resource "null_resource" "maintenance_server_a" {
  depends_on = ["aws_volume_attachment.elasticsearch_volume_attachment_a"]

  triggers {
    cluster_instance_ids = "${join(",", aws_instance.maintenance_server_a.*.id)}"
  }

  connection {
    host = "${element(aws_instance.maintenance_server_a.*.public_ip, 0)}"
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
  }

  provisioner "file" {
      content = "${data.template_file.create_elasticsearch_partition.rendered}"
      destination = "/tmp/create_elasticsearch_partition.sh"
  }

  provisioner "file" {
      content = "${data.template_file.create_pipeline_partition.rendered}"
      destination = "/tmp/create_pipeline_partition.sh"
  }

  provisioner "file" {
      content = "${data.template_file.copy_pipeline_data.rendered}"
      destination = "/tmp/copy_pipeline_data.sh"
  }

  provisioner "remote-exec" {
      inline = [
        "sudo sh /tmp/create_elasticsearch_partition.sh",
        "sudo sh /tmp/create_pipeline_partition.sh",
        "sudo sh /tmp/copy_pipeline_data.sh"
      ]
  }
}

resource "null_resource" "maintenance_server_b" {
  depends_on = ["aws_volume_attachment.elasticsearch_volume_attachment_b"]

  triggers {
    cluster_instance_ids = "${join(",", aws_instance.maintenance_server_b.*.id)}"
  }

  connection {
    host = "${element(aws_instance.maintenance_server_b.*.public_ip, 0)}"
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
  }

  provisioner "file" {
      content = "${data.template_file.create_elasticsearch_partition.rendered}"
      destination = "/tmp/create_elasticsearch_partition.sh"
  }

  provisioner "remote-exec" {
      inline = [
        "sudo sh /tmp/create_elasticsearch_partition.sh"
      ]
  }
}
