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

data "terraform_remote_state" "volumes" {
    backend = "s3"
    config {
        bucket = "nextbreakpoint-terraform-state"
        region = "${var.aws_region}"
        key = "volumes.tfstate"
    }
}

##############################################################################
# Backend servers
##############################################################################

resource "aws_security_group" "maintenance_server" {
  name = "maintenance server"
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
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "udp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  egress {
    from_port = 0
    to_port = 65535
    protocol = "udp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  tags {
    Name = "maintenance security group"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_iam_instance_profile" "maintenance_server_profile" {
    name = "maintenance_server_profile"
    roles = ["${aws_iam_role.maintenance_server_role.name}"]
}

resource "aws_iam_role" "maintenance_server_role" {
  name = "maintenance_server_role"

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
  name = "maintenance_server_role_policy"
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

  subnet_id = "${data.terraform_remote_state.network.network-public-subnet-a-id}"
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
    Name = "maintenance_server_a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "maintenance_server_b" {
  instance_type = "t2.micro"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.amazon_ubuntu_amis, var.aws_region)}"

  subnet_id = "${data.terraform_remote_state.network.network-public-subnet-b-id}"
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
    Name = "maintenance_server_b"
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

data "template_file" "maintenance_server_user_data_elasticsearch" {
  template = "${file("provision/create_single_partition.tpl")}"

  vars {
    aws_region                = "${var.aws_region}"
    device_name               = "${var.elasticsearch_device_name}"
  }
}

data "template_file" "maintenance_server_user_data_pipeline" {
  template = "${file("provision/create_single_partition.tpl")}"

  vars {
    aws_region                = "${var.aws_region}"
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
      content = "${data.template_file.maintenance_server_user_data_elasticsearch.rendered}"
      destination = "/tmp/elasticsearch.sh"
  }

  provisioner "file" {
      content = "${data.template_file.maintenance_server_user_data_pipeline.rendered}"
      destination = "/tmp/pipeline.sh"
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
      content = "${data.template_file.maintenance_server_user_data_elasticsearch.rendered}"
      destination = "/tmp/elasticsearch.sh"
  }
}
