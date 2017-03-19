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

data "terraform_remote_state" "bastion" {
    backend = "s3"
    config {
        bucket = "nextbreakpoint-terraform-state"
        region = "${var.aws_region}"
        key = "bastion.tfstate"
    }
}

##############################################################################
# Kibana servers
##############################################################################

resource "aws_security_group" "kibana_server" {
  name = "kibana server"
  description = "kibana server security group"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

  ingress {
    from_port = 9200
    to_port = 9400
    protocol = "tcp"
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
    from_port = 8300
    to_port = 8302
    protocol = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.network-vpc-cidr}"]
  }

  egress {
    from_port = 8300
    to_port = 8600
    protocol = "udp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.network-vpc-cidr}"]
  }

  egress {
    from_port = 9200
    to_port = 9400
    protocol = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.network-vpc-cidr}"]
  }

  ingress {
    from_port = 5601
    to_port = 5601
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "kibana server security group"
    Stream = "${var.stream_tag}"
  }
}

data "template_file" "kibana_server_user_data" {
  template = "${file("provision/kibana.tpl")}"

  vars {
    aws_region              = "${var.aws_region}"
    es_cluster              = "${var.es_cluster}"
    es_environment          = "${var.es_environment}"
    security_groups         = "${aws_security_group.kibana_server.id}"
    minimum_master_nodes    = "${var.minimum_master_nodes}"
    availability_zones      = "${var.availability_zones}"
    elasticsearch_data_dir  = "/mnt/elasticsearch/data"
    elasticsearch_logs_dir  = "/mnt/elasticsearch/logs"
    elasticsearch_host      = "_site_"
    elasticsearch_node      = "elasticsearch.terraform"
    consul_log_file         = "${var.consul_log_file}"
    log_group_name          = "${var.log_group_name}"
    log_stream_name         = "${var.log_stream_name}"
  }
}

resource "aws_iam_instance_profile" "kibana_server_profile" {
    name = "kibana_server_profile"
    roles = ["${var.kibana_profile}"]
}

resource "aws_instance" "kibana_server_a" {
  instance_type = "t2.medium"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.kibana_amis, var.aws_region)}"

  subnet_id = "${data.terraform_remote_state.network.network-private-subnet-a-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.kibana_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.kibana_server_profile.id}"

  connection {
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
    bastion_user = "ec2-user"
    bastion_host = "${data.terraform_remote_state.bastion.bastion-server-a-public-ip}"
  }

  tags {
    Name = "kibana_server_a"
    Stream = "${var.stream_tag}"
  }

  provisioner "file" {
      source = "provision/filebeat-index.json"
      destination = "/tmp/filebeat-index.json"
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.kibana_server_user_data.rendered}"
  }
}

resource "aws_instance" "kibana_server_b" {
  instance_type = "t2.medium"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.kibana_amis, var.aws_region)}"

  subnet_id = "${data.terraform_remote_state.network.network-private-subnet-b-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.kibana_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.kibana_server_profile.id}"

  connection {
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
    bastion_user = "ec2-user"
    bastion_host = "${data.terraform_remote_state.bastion.bastion-server-b-public-ip}"
  }

  tags {
    Name = "kibana_server_a"
    Stream = "${var.stream_tag}"
  }

  provisioner "file" {
      source = "provision/filebeat-index.json"
      destination = "/tmp/filebeat-index.json"
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.kibana_server_user_data.rendered}"
  }
}

##############################################################################
# Load balancer
##############################################################################

resource "aws_security_group" "kibana_elb" {
  name = "kibana elb"
  description = "kibana load balacer"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port = 5601
    to_port = 5601
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "kibana elb security group"
    stream = "${var.stream_tag}"
  }
}

resource "aws_elb" "kibana" {
  name = "kibana-elb"
  security_groups = ["${aws_security_group.kibana_elb.id}"]
  subnets = ["${data.terraform_remote_state.network.network-private-subnet-a-id}","${data.terraform_remote_state.network.network-private-subnet-b-id}"]

  listener {
    instance_port = 5601
    instance_protocol = "http"
    lb_port = 8500
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 3
    timeout = 10
    target = "TCP:8500"
    interval = 30
  }

  instances = ["${aws_instance.kibana_servers_a.id}", "${aws_instance.kibana_servers_b.id}"]
  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400
  internal = false

  tags {
    Name = "kibana elb"
    stream = "${var.stream_tag}"
  }
}

##############################################################################
# Route 53
##############################################################################

resource "aws_route53_record" "kibana" {
  zone_id = "${data.terraform_remote_state.vpc.hosted-zone-id}"
  name = "kibana.${data.terraform_remote_state.vpc.hosted-zone-name}"
  type = "A"

  alias {
    name = "${aws_elb.kibana.dns_name}"
    zone_id = "${aws_elb.kibana.zone_id}"
    evaluate_target_health = true
  }
}
