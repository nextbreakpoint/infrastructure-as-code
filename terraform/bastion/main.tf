##############################################################################
# Provider
##############################################################################

provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
  version = "~> 0.1"
}

provider "template" {
  version = "~> 0.1"
}

##############################################################################
# Subnets
##############################################################################

resource "aws_security_group" "bastion" {
  name = "bastion-security-group"
  description = "Bastion security group"
  vpc_id = "${data.terraform_remote_state.vpc.bastion-vpc-id}"

  ingress = {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    self = false
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["${data.terraform_remote_state.vpc.network-vpc-cidr}"]
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

  tags = {
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
    Name = "bastion-route-table"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_subnet" "bastion_a" {
  vpc_id = "${data.terraform_remote_state.vpc.bastion-vpc-id}"
  availability_zone = "${format("%s%s", var.aws_region, "a")}"
  cidr_block = "${var.aws_bastion_subnet_cidr_a}"
  map_public_ip_on_launch = true

  tags {
    Name = "bastion-subnet-a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_subnet" "bastion_b" {
  vpc_id = "${data.terraform_remote_state.vpc.bastion-vpc-id}"
  availability_zone = "${format("%s%s", var.aws_region, "b")}"
  cidr_block = "${var.aws_bastion_subnet_cidr_b}"
  map_public_ip_on_launch = true

  tags {
    Name = "bastion-subnet-b"
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

data "template_file" "bastion_server_user_data" {
  template = "${file("provision/bastion.tpl")}"
}

module "bastion_servers_a" {
  source = "./bastion"

  name = "bastion-server-a"
  stream_tag = "${var.stream_tag}"
  ami = "${lookup(var.amazon_nat_amis, var.aws_region)}"
  instance_type = "${var.bastion_instance_type}"
  key_name = "${var.key_name}"
  key_path = "${var.key_path}"
  security_groups = "${aws_security_group.bastion.id}"
  subnet_id = "${aws_subnet.bastion_a.id}"
  user_data = "${data.template_file.bastion_server_user_data.rendered}"
}

##############################################################################
# Route 53
##############################################################################

resource "aws_route53_record" "bastion" {
   zone_id = "${var.hosted_zone_id}"
   name = "bastion.${var.hosted_zone_name}"
   type = "A"
   ttl = "60"
   records = ["${module.bastion_servers_a.public-ips}"]
}
