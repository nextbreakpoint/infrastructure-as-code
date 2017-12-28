##############################################################################
# Provider
##############################################################################

provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
  version = "~> 0.1"
}

##############################################################################
# Subnets
##############################################################################

resource "aws_subnet" "network_public_a" {
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"
  availability_zone = "${format("%s%s", var.aws_region, "a")}"
  cidr_block = "${var.aws_network_public_subnet_cidr_a}"

  tags {
    Name = "public-subnet-a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_subnet" "network_public_b" {
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"
  availability_zone = "${format("%s%s", var.aws_region, "b")}"
  cidr_block = "${var.aws_network_public_subnet_cidr_b}"

  tags {
    Name = "public-subnet-b"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_subnet" "network_public_c" {
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"
  availability_zone = "${format("%s%s", var.aws_region, "c")}"
  cidr_block = "${var.aws_network_public_subnet_cidr_c}"

  tags {
    Name = "public-subnet-c"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_subnet" "network_private_a" {
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"
  availability_zone = "${format("%s%s", var.aws_region, "a")}"
  cidr_block = "${var.aws_network_private_subnet_cidr_a}"

  tags {
    Name = "private-subnet-a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_subnet" "network_private_b" {
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"
  availability_zone = "${format("%s%s", var.aws_region, "b")}"
  cidr_block = "${var.aws_network_private_subnet_cidr_b}"

  tags {
    Name = "private-subnet-b"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_subnet" "network_private_c" {
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"
  availability_zone = "${format("%s%s", var.aws_region, "c")}"
  cidr_block = "${var.aws_network_private_subnet_cidr_c}"

  tags {
    Name = "private-subnet-c"
    Stream = "${var.stream_tag}"
  }
}

##############################################################################
# Public Subnets
##############################################################################

resource "aws_route_table" "network_public" {
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.network-to-bastion-peering-connection-id}"
    cidr_block = "${data.terraform_remote_state.vpc.bastion-vpc-cidr}"
  }

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.network-to-openvpn-peering-connection-id}"
    cidr_block = "${data.terraform_remote_state.vpc.openvpn-vpc-cidr}"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${data.terraform_remote_state.vpc.network-internet-gateway-id}"
  }

  tags {
    Name = "public-route-table"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_route_table_association" "network_public_a" {
  subnet_id = "${aws_subnet.network_public_a.id}"
  route_table_id = "${aws_route_table.network_public.id}"
}

resource "aws_route_table_association" "network_public_b" {
  subnet_id = "${aws_subnet.network_public_b.id}"
  route_table_id = "${aws_route_table.network_public.id}"
}

resource "aws_route_table_association" "network_public_c" {
  subnet_id = "${aws_subnet.network_public_c.id}"
  route_table_id = "${aws_route_table.network_public.id}"
}

##############################################################################
# NAT Boxes
##############################################################################

resource "aws_security_group" "network_nat" {
  name = "NAT-security-group"
  description = "NAT security group"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.network-vpc-cidr}"]
  }

  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
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

  tags {
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "network_nat_a" {
  instance_type = "${var.nat_instance_type}"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.amazon_nat_ami, var.aws_region)}"

  subnet_id = "${aws_subnet.network_public_a.id}"
  associate_public_ip_address = "true"
  security_groups = ["${aws_security_group.network_nat.id}"]
  key_name = "${var.key_name}"

  source_dest_check = false

  connection {
    # The default username for our AMI
    user = "ec2-user"
    type = "ssh"
    key_file = "${var.key_path}"
  }

  tags {
    Name = "nat-box-a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "network_nat_b" {
  instance_type = "${var.nat_instance_type}"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.amazon_nat_ami, var.aws_region)}"

  subnet_id = "${aws_subnet.network_public_b.id}"
  associate_public_ip_address = "true"
  security_groups = ["${aws_security_group.network_nat.id}"]
  key_name = "${var.key_name}"

  source_dest_check = false

  connection {
    # The default username for our AMI
    user = "ec2-user"
    type = "ssh"
    key_file = "${var.key_path}"
  }

  tags {
    Name = "nat-box-b"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "network_nat_c" {
  instance_type = "${var.nat_instance_type}"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.amazon_nat_ami, var.aws_region)}"

  subnet_id = "${aws_subnet.network_public_c.id}"
  associate_public_ip_address = "true"
  security_groups = ["${aws_security_group.network_nat.id}"]
  key_name = "${var.key_name}"

  source_dest_check = false

  connection {
    # The default username for our AMI
    user = "ec2-user"
    type = "ssh"
    key_file = "${var.key_path}"
  }

  tags {
    Name = "nat-box-c"
    Stream = "${var.stream_tag}"
  }
}

/*
resource "aws_eip" "net_eip_a" {
}

resource "aws_eip" "net_eip_b" {
}

resource "aws_eip" "net_eip_c" {
}

resource "aws_nat_gateway" "net_gateway_a" {
    allocation_id = "${aws_eip.net_eip_a.id}"
    subnet_id = "${data.terraform_remote_state.vpc.network-public-subnet-a-id}"
}

resource "aws_nat_gateway" "net_gateway_b" {
    allocation_id = "${aws_eip.net_eip_b.id}"
    subnet_id = "${data.terraform_remote_state.vpc.network-public-subnet-b-id}"
}

resource "aws_nat_gateway" "net_gateway_c" {
    allocation_id = "${aws_eip.net_eip_c.id}"
    subnet_id = "${data.terraform_remote_state.vpc.network-public-subnet-c-id}"
}
*/

##############################################################################
# Private subnets
##############################################################################

resource "aws_route_table" "network_private_a" {
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.network-to-bastion-peering-connection-id}"
    cidr_block = "${data.terraform_remote_state.vpc.bastion-vpc-cidr}"
  }

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.network-to-openvpn-peering-connection-id}"
    cidr_block = "${data.terraform_remote_state.vpc.openvpn-vpc-cidr}"
  }

  route {
    cidr_block = "0.0.0.0/0"
    instance_id = "${aws_instance.network_nat_a.id}"
    #nat_gateway_id = "${aws_nat_gateway.net_gateway_a.id}"
  }

  tags {
    Name = "private-route-table-a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_route_table" "network_private_b" {
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.network-to-bastion-peering-connection-id}"
    cidr_block = "${data.terraform_remote_state.vpc.bastion-vpc-cidr}"
  }

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.network-to-openvpn-peering-connection-id}"
    cidr_block = "${data.terraform_remote_state.vpc.openvpn-vpc-cidr}"
  }

  route {
    cidr_block = "0.0.0.0/0"
    instance_id = "${aws_instance.network_nat_b.id}"
    #nat_gateway_id = "${aws_nat_gateway.net_gateway_b.id}"
  }

  tags {
    Name = "private-route-table-b"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_route_table" "network_private_c" {
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.network-to-bastion-peering-connection-id}"
    cidr_block = "${data.terraform_remote_state.vpc.bastion-vpc-cidr}"
  }

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.network-to-openvpn-peering-connection-id}"
    cidr_block = "${data.terraform_remote_state.vpc.openvpn-vpc-cidr}"
  }

  route {
    cidr_block = "0.0.0.0/0"
    instance_id = "${aws_instance.network_nat_c.id}"
    #nat_gateway_id = "${aws_nat_gateway.net_gateway_c.id}"
  }

  tags {
    Name = "private-route-table-c"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_route_table_association" "network_private_a" {
  subnet_id = "${aws_subnet.network_private_a.id}"
  route_table_id = "${aws_route_table.network_private_a.id}"
}

resource "aws_route_table_association" "network_private_b" {
  subnet_id = "${aws_subnet.network_private_b.id}"
  route_table_id = "${aws_route_table.network_private_b.id}"
}

resource "aws_route_table_association" "network_private_c" {
  subnet_id = "${aws_subnet.network_private_c.id}"
  route_table_id = "${aws_route_table.network_private_c.id}"
}
