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
# ZooKeeper servers
##############################################################################

resource "aws_security_group" "zookeeper_server" {
  name = "zookeeper server"
  description = "zookeeper server security group"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 2181
    to_port = 2181
    protocol = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.network-vpc-cidr}"]
  }

  ingress {
    from_port = 2888
    to_port = 2888
    protocol = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.network-vpc-cidr}"]
  }

  ingress {
    from_port = 3888
    to_port = 3888
    protocol = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.network-vpc-cidr}"]
  }

  ingress {
    from_port = 8300
    to_port = 8302
    protocol = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.network-vpc-cidr}"]
  }

  ingress {
    from_port = 8300
    to_port = 8302
    protocol = "udp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.network-vpc-cidr}"]
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
    from_port = 2181
    to_port = 2181
    protocol = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.network-vpc-cidr}"]
  }

  egress {
    from_port = 2888
    to_port = 2888
    protocol = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.network-vpc-cidr}"]
  }

  egress {
    from_port = 3888
    to_port = 3888
    protocol = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.network-vpc-cidr}"]
  }

  egress {
    from_port = 8300
    to_port = 8302
    protocol = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.network-vpc-cidr}"]
  }

  egress {
    from_port = 8300
    to_port = 8302
    protocol = "udp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.network-vpc-cidr}"]
  }

  tags {
    Name = "zookeeper server security group"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_iam_instance_profile" "zookeeper_server_profile" {
    name = "zookeeper_server_profile"
    roles = ["${var.zookeeper_profile}"]
}

resource "aws_instance" "zookeeper_server_a" {
  instance_type = "${var.aws_zookeeper_instance_type}"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.zookeeper_amis, var.aws_region)}"

  subnet_id = "${data.terraform_remote_state.network.network-private-subnet-a-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.zookeeper_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.zookeeper_server_profile.id}"

  tags {
    Name = "zookeeper_server_a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "zookeeper_server_b" {
  instance_type = "${var.aws_zookeeper_instance_type}"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.zookeeper_amis, var.aws_region)}"

  subnet_id = "${data.terraform_remote_state.network.network-private-subnet-b-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.zookeeper_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.zookeeper_server_profile.id}"

  tags {
    Name = "zookeeper_server_b"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "zookeeper_server_c" {
  instance_type = "${var.aws_zookeeper_instance_type}"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.zookeeper_amis, var.aws_region)}"

  subnet_id = "${data.terraform_remote_state.network.network-private-subnet-c-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.zookeeper_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.zookeeper_server_profile.id}"

  tags {
    Name = "zookeeper_server_c"
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
    bastion_host = "bastion.nextbreakpoint.com"
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
    bastion_host = "bastion.nextbreakpoint.com"
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
    bastion_host = "bastion.nextbreakpoint.com"
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
