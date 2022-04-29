##############################################################################
# Providers
##############################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region  = "${var.aws_region}"
}

##############################################################################
# Public Subnets
##############################################################################

resource "aws_subnet" "platform_public_a" {
  vpc_id                  = "${data.terraform_remote_state.vpc.outputs.platform-vpc-id}"
  availability_zone       = "${format("%s%s", var.aws_region, "a")}"
  cidr_block              = "${var.aws_platform_public_subnet_cidr_a}"
  map_public_ip_on_launch = true

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-platform-pub-a"
  }
}

resource "aws_subnet" "platform_public_b" {
  vpc_id                  = "${data.terraform_remote_state.vpc.outputs.platform-vpc-id}"
  availability_zone       = "${format("%s%s", var.aws_region, "b")}"
  cidr_block              = "${var.aws_platform_public_subnet_cidr_b}"
  map_public_ip_on_launch = true

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-platform-pub-b"
  }
}

resource "aws_subnet" "platform_public_c" {
  vpc_id                  = "${data.terraform_remote_state.vpc.outputs.platform-vpc-id}"
  availability_zone       = "${format("%s%s", var.aws_region, "c")}"
  cidr_block              = "${var.aws_platform_public_subnet_cidr_c}"
  map_public_ip_on_launch = true

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-platform-pub-c"
  }
}

resource "aws_route_table" "platform_public" {
  vpc_id = "${data.terraform_remote_state.vpc.outputs.platform-vpc-id}"

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.outputs.platform-to-bastion-peering-connection-id}"
    cidr_block                = "${data.terraform_remote_state.vpc.outputs.bastion-vpc-cidr}"
  }

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.outputs.platform-to-openvpn-peering-connection-id}"
    cidr_block                = "${data.terraform_remote_state.vpc.outputs.openvpn-vpc-cidr}"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${data.terraform_remote_state.vpc.outputs.platform-internet-gateway-id}"
  }

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-platform-pub"
  }
}

resource "aws_route_table_association" "platform_public_a" {
  subnet_id      = "${aws_subnet.platform_public_a.id}"
  route_table_id = "${aws_route_table.platform_public.id}"
}

resource "aws_route_table_association" "platform_public_b" {
  subnet_id      = "${aws_subnet.platform_public_b.id}"
  route_table_id = "${aws_route_table.platform_public.id}"
}

resource "aws_route_table_association" "platform_public_c" {
  subnet_id      = "${aws_subnet.platform_public_c.id}"
  route_table_id = "${aws_route_table.platform_public.id}"
}

resource "aws_subnet" "bastion_a" {
  vpc_id                  = "${data.terraform_remote_state.vpc.outputs.bastion-vpc-id}"
  availability_zone       = "${format("%s%s", var.aws_region, "a")}"
  cidr_block              = "${var.aws_bastion_subnet_cidr_a}"
  map_public_ip_on_launch = true

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-bastion-a"
  }
}

resource "aws_subnet" "bastion_b" {
  vpc_id                  = "${data.terraform_remote_state.vpc.outputs.bastion-vpc-id}"
  availability_zone       = "${format("%s%s", var.aws_region, "b")}"
  cidr_block              = "${var.aws_bastion_subnet_cidr_b}"
  map_public_ip_on_launch = true

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-bastion-b"
  }
}

resource "aws_subnet" "bastion_c" {
  vpc_id                  = "${data.terraform_remote_state.vpc.outputs.bastion-vpc-id}"
  availability_zone       = "${format("%s%s", var.aws_region, "c")}"
  cidr_block              = "${var.aws_bastion_subnet_cidr_c}"
  map_public_ip_on_launch = true

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-bastion-c"
  }
}

resource "aws_route_table" "bastion" {
  vpc_id = "${data.terraform_remote_state.vpc.outputs.bastion-vpc-id}"

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.outputs.platform-to-bastion-peering-connection-id}"
    cidr_block                = "${data.terraform_remote_state.vpc.outputs.platform-vpc-cidr}"
  }

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.outputs.bastion-to-openvpn-peering-connection-id}"
    cidr_block                = "${data.terraform_remote_state.vpc.outputs.openvpn-vpc-cidr}"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${data.terraform_remote_state.vpc.outputs.bastion-internet-gateway-id}"
  }

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-bastion"
  }
}

resource "aws_route_table_association" "bastion_a" {
  subnet_id      = "${aws_subnet.bastion_a.id}"
  route_table_id = "${aws_route_table.bastion.id}"
}

resource "aws_route_table_association" "bastion_b" {
  subnet_id      = "${aws_subnet.bastion_b.id}"
  route_table_id = "${aws_route_table.bastion.id}"
}

resource "aws_route_table_association" "bastion_c" {
  subnet_id      = "${aws_subnet.bastion_c.id}"
  route_table_id = "${aws_route_table.bastion.id}"
}

resource "aws_subnet" "openvpn_a" {
  vpc_id                  = "${data.terraform_remote_state.vpc.outputs.openvpn-vpc-id}"
  availability_zone       = "${format("%s%s", var.aws_region, "a")}"
  cidr_block              = "${var.aws_openvpn_subnet_cidr_a}"
  map_public_ip_on_launch = true

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-openvpn-a"
  }
}

resource "aws_subnet" "openvpn_b" {
  vpc_id                  = "${data.terraform_remote_state.vpc.outputs.openvpn-vpc-id}"
  availability_zone       = "${format("%s%s", var.aws_region, "b")}"
  cidr_block              = "${var.aws_openvpn_subnet_cidr_b}"
  map_public_ip_on_launch = true

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-openvpn-b"
  }
}

resource "aws_subnet" "openvpn_c" {
  vpc_id                  = "${data.terraform_remote_state.vpc.outputs.openvpn-vpc-id}"
  availability_zone       = "${format("%s%s", var.aws_region, "c")}"
  cidr_block              = "${var.aws_openvpn_subnet_cidr_c}"
  map_public_ip_on_launch = true

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-openvpn-c"
  }
}

resource "aws_route_table" "openvpn" {
  vpc_id = "${data.terraform_remote_state.vpc.outputs.openvpn-vpc-id}"

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.outputs.platform-to-openvpn-peering-connection-id}"
    cidr_block                = "${data.terraform_remote_state.vpc.outputs.platform-vpc-cidr}"
  }

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.outputs.bastion-to-openvpn-peering-connection-id}"
    cidr_block                = "${data.terraform_remote_state.vpc.outputs.bastion-vpc-cidr}"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${data.terraform_remote_state.vpc.outputs.openvpn-internet-gateway-id}"
  }

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-openvpn"
  }
}

resource "aws_route_table_association" "openvpn_a" {
  subnet_id      = "${aws_subnet.openvpn_a.id}"
  route_table_id = "${aws_route_table.openvpn.id}"
}

resource "aws_route_table_association" "openvpn_b" {
  subnet_id      = "${aws_subnet.openvpn_b.id}"
  route_table_id = "${aws_route_table.openvpn.id}"
}

resource "aws_route_table_association" "openvpn_c" {
  subnet_id      = "${aws_subnet.openvpn_c.id}"
  route_table_id = "${aws_route_table.openvpn.id}"
}

##############################################################################
# NAT Boxes
##############################################################################

resource "aws_security_group" "platform_nat" {
  name        = "${var.environment}-${var.colour}-NAT"
  description = "NAT security group"
  vpc_id      = "${data.terraform_remote_state.vpc.outputs.platform-vpc-id}"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.outputs.platform-vpc-cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.outputs.platform-vpc-cidr}"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
  }
}

/*
resource "aws_instance" "platform_nat_a" {
  instance_type = "${var.enable_nat_gateways_instance_type}"

  ami = "${lookup(var.amazon_nat_ami, var.aws_region)}"

  subnet_id                   = "${aws_subnet.platform_public_a.id}"
  associate_public_ip_address = "true"
  vpc_security_group_ids      = ["${aws_security_group.platform_nat.id}"]
  key_name                    = "${var.environment}-${var.colour}-${var.key_name}"

  source_dest_check = false

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-natbox-a"
  }
}

resource "aws_instance" "platform_nat_b" {
  instance_type = "${var.enable_nat_gateways_instance_type}"

  ami = "${lookup(var.amazon_nat_ami, var.aws_region)}"

  subnet_id                   = "${aws_subnet.platform_public_b.id}"
  associate_public_ip_address = "true"
  vpc_security_group_ids      = ["${aws_security_group.platform_nat.id}"]
  key_name                    = "${var.environment}-${var.colour}-${var.key_name}"

  source_dest_check = false

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-natbox-b"
  }
}

resource "aws_instance" "platform_nat_c" {
  instance_type = "${var.enable_nat_gateways_instance_type}"

  ami = "${lookup(var.amazon_nat_ami, var.aws_region)}"

  subnet_id                   = "${aws_subnet.platform_public_c.id}"
  associate_public_ip_address = "true"
  vpc_security_group_ids      = ["${aws_security_group.platform_nat.id}"]
  key_name                    = "${var.environment}-${var.colour}-${var.key_name}"

  source_dest_check = false

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-natbox-c"
  }
}
*/

resource "aws_eip" "net_eip_a" {
}

resource "aws_eip" "net_eip_b" {
}

resource "aws_eip" "net_eip_c" {
}

resource "aws_nat_gateway" "nat_gateway_a" {
    count = "${var.enable_nat_gateways == true ? 1 : 0}"
    allocation_id = "${aws_eip.net_eip_a.id}"
    connectivity_type = "public"
    subnet_id = "${aws_subnet.platform_public_a.id}"

    tags = {
      Environment = "${var.environment}"
      Colour      = "${var.colour}"
      Name        = "${var.environment}-${var.colour}-natgw-a"
    }
}

resource "aws_nat_gateway" "nat_gateway_b" {
    count = "${var.enable_nat_gateways == true ? 1 : 0}"
    allocation_id = "${aws_eip.net_eip_b.id}"
    connectivity_type = "public"
    subnet_id = "${aws_subnet.platform_public_b.id}"

    tags = {
      Environment = "${var.environment}"
      Colour      = "${var.colour}"
      Name        = "${var.environment}-${var.colour}-natgw-b"
    }
}

resource "aws_nat_gateway" "nat_gateway_c" {
    count = "${var.enable_nat_gateways == true ? 1 : 0}"
    allocation_id = "${aws_eip.net_eip_c.id}"
    connectivity_type = "public"
    subnet_id = "${aws_subnet.platform_public_c.id}"

    tags = {
      Environment = "${var.environment}"
      Colour      = "${var.colour}"
      Name        = "${var.environment}-${var.colour}-natgw-c"
    }
}

##############################################################################
# Private subnets
##############################################################################

resource "aws_subnet" "platform_private_a" {
  vpc_id            = "${data.terraform_remote_state.vpc.outputs.platform-vpc-id}"
  availability_zone = "${format("%s%s", var.aws_region, "a")}"
  cidr_block        = "${var.aws_platform_private_subnet_cidr_a}"

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-platform-int-a"
  }
}

resource "aws_subnet" "platform_private_b" {
  vpc_id            = "${data.terraform_remote_state.vpc.outputs.platform-vpc-id}"
  availability_zone = "${format("%s%s", var.aws_region, "b")}"
  cidr_block        = "${var.aws_platform_private_subnet_cidr_b}"

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-platform-int-b"
  }
}

resource "aws_subnet" "platform_private_c" {
  vpc_id            = "${data.terraform_remote_state.vpc.outputs.platform-vpc-id}"
  availability_zone = "${format("%s%s", var.aws_region, "c")}"
  cidr_block        = "${var.aws_platform_private_subnet_cidr_c}"

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-platform-int-c"
  }
}

resource "aws_route_table" "platform_private_a" {
  count = "${var.enable_nat_gateways == true ? 1 : 0}"

  vpc_id = "${data.terraform_remote_state.vpc.outputs.platform-vpc-id}"

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.outputs.platform-to-bastion-peering-connection-id}"
    cidr_block                = "${data.terraform_remote_state.vpc.outputs.bastion-vpc-cidr}"
  }

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.outputs.platform-to-openvpn-peering-connection-id}"
    cidr_block                = "${data.terraform_remote_state.vpc.outputs.openvpn-vpc-cidr}"
  }

  route {
    cidr_block  = "0.0.0.0/0"
    #instance_id = "${aws_instance.platform_nat_a.id}"
    nat_gateway_id = "${aws_nat_gateway.nat_gateway_a[0].id}"
  }

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-platform-int-a"
  }
}

resource "aws_route_table" "platform_private_b" {
  count = "${var.enable_nat_gateways == true ? 1 : 0}"

  vpc_id = "${data.terraform_remote_state.vpc.outputs.platform-vpc-id}"

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.outputs.platform-to-bastion-peering-connection-id}"
    cidr_block                = "${data.terraform_remote_state.vpc.outputs.bastion-vpc-cidr}"
  }

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.outputs.platform-to-openvpn-peering-connection-id}"
    cidr_block                = "${data.terraform_remote_state.vpc.outputs.openvpn-vpc-cidr}"
  }

  route {
    cidr_block  = "0.0.0.0/0"
    #instance_id = "${aws_instance.platform_nat_b.id}"
    nat_gateway_id = "${aws_nat_gateway.nat_gateway_b[0].id}"
  }

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-platform-int-b"
  }
}

resource "aws_route_table" "platform_private_c" {
  count = "${var.enable_nat_gateways == true ? 1 : 0}"

  vpc_id = "${data.terraform_remote_state.vpc.outputs.platform-vpc-id}"

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.outputs.platform-to-bastion-peering-connection-id}"
    cidr_block                = "${data.terraform_remote_state.vpc.outputs.bastion-vpc-cidr}"
  }

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.outputs.platform-to-openvpn-peering-connection-id}"
    cidr_block                = "${data.terraform_remote_state.vpc.outputs.openvpn-vpc-cidr}"
  }

  route {
    cidr_block  = "0.0.0.0/0"
    #instance_id = "${aws_instance.platform_nat_c.id}"
    nat_gateway_id = "${aws_nat_gateway.nat_gateway_c[0].id}"
  }

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-platform-int-c"
  }
}

resource "aws_route_table" "platform_private_a_no_nat" {
  count = "${var.enable_nat_gateways == true ? 0 : 1}"

  vpc_id = "${data.terraform_remote_state.vpc.outputs.platform-vpc-id}"

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.outputs.platform-to-bastion-peering-connection-id}"
    cidr_block                = "${data.terraform_remote_state.vpc.outputs.bastion-vpc-cidr}"
  }

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.outputs.platform-to-openvpn-peering-connection-id}"
    cidr_block                = "${data.terraform_remote_state.vpc.outputs.openvpn-vpc-cidr}"
  }

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-platform-int-a"
  }
}

resource "aws_route_table" "platform_private_b_no_nat" {
  count = "${var.enable_nat_gateways == true ? 0 : 1}"

  vpc_id = "${data.terraform_remote_state.vpc.outputs.platform-vpc-id}"

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.outputs.platform-to-bastion-peering-connection-id}"
    cidr_block                = "${data.terraform_remote_state.vpc.outputs.bastion-vpc-cidr}"
  }

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.outputs.platform-to-openvpn-peering-connection-id}"
    cidr_block                = "${data.terraform_remote_state.vpc.outputs.openvpn-vpc-cidr}"
  }

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-platform-int-b"
  }
}

resource "aws_route_table" "platform_private_c_no_nat" {
  count = "${var.enable_nat_gateways == true ? 0 : 1}"

  vpc_id = "${data.terraform_remote_state.vpc.outputs.platform-vpc-id}"

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.outputs.platform-to-bastion-peering-connection-id}"
    cidr_block                = "${data.terraform_remote_state.vpc.outputs.bastion-vpc-cidr}"
  }

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.outputs.platform-to-openvpn-peering-connection-id}"
    cidr_block                = "${data.terraform_remote_state.vpc.outputs.openvpn-vpc-cidr}"
  }

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
    Name        = "${var.environment}-${var.colour}-platform-int-c"
  }
}

resource "aws_route_table_association" "platform_private_a" {
  count = "${var.enable_nat_gateways == true ? 1 : 0}"

  subnet_id      = "${aws_subnet.platform_private_a.id}"
  route_table_id = "${aws_route_table.platform_private_a[0].id}"
}

resource "aws_route_table_association" "platform_private_b" {
  count = "${var.enable_nat_gateways == true ? 1 : 0}"

  subnet_id      = "${aws_subnet.platform_private_b.id}"
  route_table_id = "${aws_route_table.platform_private_b[0].id}"
}

resource "aws_route_table_association" "platform_private_c" {
  count = "${var.enable_nat_gateways == true ? 1 : 0}"

  subnet_id      = "${aws_subnet.platform_private_c.id}"
  route_table_id = "${aws_route_table.platform_private_c[0].id}"
}

resource "aws_route_table_association" "platform_private_a_no_nat" {
  count = "${var.enable_nat_gateways == true ? 0 : 1}"

  subnet_id      = "${aws_subnet.platform_private_a.id}"
  route_table_id = "${aws_route_table.platform_private_a_no_nat[0].id}"
}

resource "aws_route_table_association" "platform_private_b_no_nat" {
  count = "${var.enable_nat_gateways == true ? 0 : 1}"

  subnet_id      = "${aws_subnet.platform_private_b.id}"
  route_table_id = "${aws_route_table.platform_private_b_no_nat[0].id}"
}

resource "aws_route_table_association" "platform_private_c_no_nat" {
  count = "${var.enable_nat_gateways == true ? 0 : 1}"

  subnet_id      = "${aws_subnet.platform_private_c.id}"
  route_table_id = "${aws_route_table.platform_private_c_no_nat[0].id}"
}
