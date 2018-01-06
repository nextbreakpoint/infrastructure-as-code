##############################################################################
# Outputs
##############################################################################

output "network-vpc-id" {
  value = "${aws_vpc.network.id}"
}

output "bastion-vpc-id" {
  value = "${aws_vpc.bastion.id}"
}

output "openvpn-vpc-id" {
  value = "${aws_vpc.openvpn.id}"
}

output "network-vpc-cidr" {
  value = "${aws_vpc.network.cidr_block}"
}

output "bastion-vpc-cidr" {
  value = "${aws_vpc.bastion.cidr_block}"
}

output "openvpn-vpc-cidr" {
  value = "${aws_vpc.openvpn.cidr_block}"
}

output "network-internet-gateway-id" {
  value = "${aws_internet_gateway.network.id}"
}

output "bastion-internet-gateway-id" {
  value = "${aws_internet_gateway.bastion.id}"
}

output "openvpn-internet-gateway-id" {
  value = "${aws_internet_gateway.openvpn.id}"
}

output "network-to-bastion-peering-connection-id" {
  value = "${aws_vpc_peering_connection.network_to_bastion.id}"
}

output "network-to-openvpn-peering-connection-id" {
  value = "${aws_vpc_peering_connection.network_to_openvpn.id}"
}
