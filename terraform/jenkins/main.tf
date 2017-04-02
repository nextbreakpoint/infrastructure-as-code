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
        key = "network_dev.tfstate"
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
# Jenkins server
##############################################################################

resource "aws_security_group" "jenkins_server" {
  name = "jenkins server"
  description = "jenkins server security group"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8081
    to_port = 8081
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 9000
    to_port = 9000
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

  egress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 8081
    to_port = 8081
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 9000
    to_port = 9000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "web server security group"
    Stream = "${var.stream_tag}"
  }
}

data "template_file" "jenkins_server_user_data" {
  template = "${file("provision/jenkins.tpl")}"

  vars {
    aws_region              = "${var.aws_region}"
    environment             = "${var.environment}"
    security_groups         = "${aws_security_group.jenkins_server.id}"
    consul_log_file         = "${var.consul_log_file}"
    volume_name             = "${var.volume_name}"
    log_group_name          = "${var.log_group_name}"
    log_stream_name         = "${var.log_stream_name}"
    logstash_host           = "logstash.${data.terraform_remote_state.vpc.hosted-zone-name}"
    jenkins_host            = "${aws_instance.jenkins_server.private_ip}"
    sonarqube_host          = "${aws_instance.jenkins_server.private_ip}"
    artifactory_host        = "${aws_instance.jenkins_server.private_ip}"
    pipeline_data_dir       = "/mnt/pipeline"
  }
}

resource "aws_iam_instance_profile" "jenkins_server_profile" {
    name = "jenkins_server_profile"
    roles = ["${var.jenkins_server_profile}"]
}

resource "aws_instance" "jenkins_server" {
  instance_type = "t2.xlarge"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.jenkins_amis, var.aws_region)}"

  subnet_id = "${data.terraform_remote_state.network.network-public-subnet-a-id}"
  associate_public_ip_address = "true"
  security_groups = ["${aws_security_group.jenkins_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.jenkins_server_profile.id}"

  connection {
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
  }

  tags {
    Name = "jenkins_server"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_volume_attachment" "pipeline_volume_attachment_a" {
  device_name = "${var.volume_name}"
  volume_id = "${data.terraform_remote_state.volumes.pipeline-volume-a-id}"
  instance_id = "${aws_instance.jenkins_server.id}"
  skip_destroy = true
}

resource "null_resource" "jenkins_server" {
  depends_on = ["aws_volume_attachment.pipeline_volume_attachment_a"]

  triggers {
    cluster_instance_ids = "${join(",", aws_instance.jenkins_server.*.id)}"
  }

  connection {
    host = "${element(aws_instance.jenkins_server.*.public_ip, 0)}"
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
    #bastion_user = "ec2-user"
    #bastion_host = "${data.terraform_remote_state.bastion.bastion-server-a-public-ip}"
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.jenkins_server_user_data.rendered}"
  }
}

##############################################################################
# Route 53
##############################################################################

resource "aws_route53_record" "jenkins" {
  zone_id = "${data.terraform_remote_state.vpc.hosted-zone-id}"
  name = "jenkins.${data.terraform_remote_state.vpc.hosted-zone-name}"
  type = "A"
  ttl = "300"
  records = ["${aws_instance.jenkins_server.*.private_ip}"]
}

resource "aws_route53_record" "sonarqube" {
  zone_id = "${data.terraform_remote_state.vpc.hosted-zone-id}"
  name = "sonarqube.${data.terraform_remote_state.vpc.hosted-zone-name}"
  type = "A"
  ttl = "300"
  records = ["${aws_instance.jenkins_server.*.private_ip}"]
}

resource "aws_route53_record" "artifactory" {
  zone_id = "${data.terraform_remote_state.vpc.hosted-zone-id}"
  name = "artifactory.${data.terraform_remote_state.vpc.hosted-zone-name}"
  type = "A"
  ttl = "300"
  records = ["${aws_instance.jenkins_server.*.private_ip}"]
}


