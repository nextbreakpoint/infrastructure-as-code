output "hosted-zone-id" {
  value = "${aws_route53_zone.network.id}"
}

output "hosted-zone-name" {
  value = "${aws_route53_zone.network.name}"
}

output "network-vpc-id" {
  value = "${aws_vpc.network.id}"
}

output "bastion-vpc-id" {
  value = "${aws_vpc.bastion.id}"
}

output "network-vpc-cidr" {
  value = "${aws_vpc.network.cidr_block}"
}

output "bastion-vpc-cidr" {
  value = "${aws_vpc.bastion.cidr_block}"
}

output "network-internet-gateway-id" {
  value = "${aws_internet_gateway.network.id}"
}

output "bastion-internet-gateway-id" {
  value = "${aws_internet_gateway.bastion.id}"
}

output "network-to-bastion-peering-connection-id" {
  value = "${aws_vpc_peering_connection.network_to_bastion.id}"
}

output "network-public-subnet-a-id" {
  value = "${aws_subnet.network_public_a.id}"
}

output "network-public-subnet-b-id" {
  value = "${aws_subnet.network_public_b.id}"
}

output "network-public-subnet-c-id" {
  value = "${aws_subnet.network_public_c.id}"
}

output "network-private-subnet-a-id" {
  value = "${aws_subnet.network_private_a.id}"
}

output "network-private-subnet-b-id" {
  value = "${aws_subnet.network_private_b.id}"
}

output "network-private-subnet-c-id" {
  value = "${aws_subnet.network_private_c.id}"
}
