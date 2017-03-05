##############################################################################
# Provider
##############################################################################

provider "aws" {
  region = "${var.aws_region}"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
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
        profile = "default"
        access_key = "${var.aws_access_key}"
        secret_key = "${var.aws_secret_key}"
    }
}

##############################################################################
# Route 53
##############################################################################

resource "aws_route53_record" "bastion" {
   zone_id = "${data.terraform_remote_state.vpc.hosted-zone-id}"
   name = "bastion.${data.terraform_remote_state.vpc.hosted-zone-name}"
   type = "A"
   ttl = "300"
   records = ["${module.bastion_servers_a.public-ips}","${module.bastion_servers_b.public-ips}"]
}

##############################################################################
# Public Subnets
##############################################################################

resource "aws_security_group" "bastion" {
  name = "bastion"
  description = "Allow access from allowed_network to SSH, and NAT internal traffic"
  vpc_id = "${data.terraform_remote_state.vpc.bastion-vpc-id}"

  ingress = {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    self = false
  }

  egress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.network-vpc-cidr}"]
  }

  tags = {
    Name = "bastion security group"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_route_table" "bastion" {
  vpc_id = "${data.terraform_remote_state.vpc.bastion-vpc-id}"

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.network-to-bastion-peering-connection-id}"
    cidr_block = "${data.terraform_remote_state.vpc.network-vpc-cidr}"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${data.terraform_remote_state.vpc.bastion-internet-gateway-id}"
  }

  tags {
    Name = "bastion route table"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_subnet" "bastion_a" {
  vpc_id = "${data.terraform_remote_state.vpc.bastion-vpc-id}"
  availability_zone = "${format("%s%s", var.aws_region, "a")}"
  cidr_block = "${var.aws_bastion_subnet_cidr_a}"

  tags {
    Name = "bastion subnet a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_subnet" "bastion_b" {
  vpc_id = "${data.terraform_remote_state.vpc.bastion-vpc-id}"
  availability_zone = "${format("%s%s", var.aws_region, "b")}"
  cidr_block = "${var.aws_bastion_subnet_cidr_b}"

  tags {
    Name = "bastion subnet b"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_route_table_association" "bastion_a" {
  subnet_id = "${aws_subnet.bastion_a.id}"
  route_table_id = "${aws_route_table.bastion.id}"
}

resource "aws_route_table_association" "bastion_b" {
  subnet_id = "${aws_subnet.bastion_b.id}"
  route_table_id = "${aws_route_table.bastion.id}"
}

##############################################################################
# Bastion Servers
##############################################################################

module "bastion_servers_a" {
  source = "./bastion"

  name = "bastion_server_a"
  stream_tag = "${var.stream_tag}"
  ami = "${lookup(var.amazon_nat_amis, var.aws_region)}"
  instance_type = "t2.micro"
  key_name = "${var.key_name}"
  key_path = "${var.key_path}"
  security_groups = "${aws_security_group.bastion.id}"
  subnet_id = "${aws_subnet.bastion_a.id}"
}

module "bastion_servers_b" {
  source = "./bastion"

  name = "bastion_server_b"
  stream_tag = "${var.stream_tag}"
  ami = "${lookup(var.amazon_nat_amis, var.aws_region)}"
  instance_type = "t2.micro"
  key_name = "${var.key_name}"
  key_path = "${var.key_path}"
  security_groups = "${aws_security_group.bastion.id}"
  subnet_id = "${aws_subnet.bastion_b.id}"
}
