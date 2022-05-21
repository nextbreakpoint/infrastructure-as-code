output "platform-vpc-id" {
  value = "${aws_vpc.platform.id}"
}

output "bastion-vpc-id" {
  value = "${aws_vpc.bastion.id}"
}

output "openvpn-vpc-id" {
  value = "${aws_vpc.openvpn.id}"
}

output "platform-vpc-cidr" {
  value = "${aws_vpc.platform.cidr_block}"
}

output "bastion-vpc-cidr" {
  value = "${aws_vpc.bastion.cidr_block}"
}

output "openvpn-vpc-cidr" {
  value = "${aws_vpc.openvpn.cidr_block}"
}

output "platform-internet-gateway-id" {
  value = "${aws_internet_gateway.platform.id}"
}

output "bastion-internet-gateway-id" {
  value = "${aws_internet_gateway.bastion.id}"
}

output "openvpn-internet-gateway-id" {
  value = "${aws_internet_gateway.openvpn.id}"
}

output "platform-to-bastion-peering-connection-id" {
  value = "${aws_vpc_peering_connection.bastion_to_platform.id}"
}

output "platform-to-openvpn-peering-connection-id" {
  value = "${aws_vpc_peering_connection.openvpn_to_platform.id}"
}

output "bastion-to-openvpn-peering-connection-id" {
  value = "${aws_vpc_peering_connection.bastion_to_openvpn.id}"
}
