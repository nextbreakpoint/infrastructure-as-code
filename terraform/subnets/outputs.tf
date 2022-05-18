##############################################################################
# Outputs
##############################################################################

output "platform-public-subnet-a-id" {
  value = "${aws_subnet.platform_public_a.id}"
}

output "platform-public-subnet-b-id" {
  value = "${aws_subnet.platform_public_b.id}"
}

output "platform-public-subnet-c-id" {
  value = "${aws_subnet.platform_public_c.id}"
}

output "platform-private-subnet-a-id" {
  value = "${aws_subnet.platform_private_a.id}"
}

output "platform-private-subnet-b-id" {
  value = "${aws_subnet.platform_private_b.id}"
}

output "platform-private-subnet-c-id" {
  value = "${aws_subnet.platform_private_c.id}"
}

output "bastion-public-subnet-a-id" {
  value = "${aws_subnet.bastion_a.id}"
}

output "bastion-public-subnet-b-id" {
  value = "${aws_subnet.bastion_b.id}"
}

output "bastion-public-subnet-c-id" {
  value = "${aws_subnet.bastion_c.id}"
}

output "openvpn-public-subnet-a-id" {
  value = "${aws_subnet.openvpn_a.id}"
}

output "openvpn-public-subnet-b-id" {
  value = "${aws_subnet.openvpn_b.id}"
}

output "openvpn-public-subnet-c-id" {
  value = "${aws_subnet.openvpn_c.id}"
}

output "platform-public-subnet-a-cidr" {
  value = "${aws_subnet.platform_public_a.cidr_block}"
}

output "platform-public-subnet-b-cidr" {
  value = "${aws_subnet.platform_public_b.cidr_block}"
}

output "platform-public-subnet-c-cidr" {
  value = "${aws_subnet.platform_public_c.cidr_block}"
}

output "platform-private-subnet-a-cidr" {
  value = "${aws_subnet.platform_private_a.cidr_block}"
}

output "platform-private-subnet-b-cidr" {
  value = "${aws_subnet.platform_private_b.cidr_block}"
}

output "platform-private-subnet-c-cidr" {
  value = "${aws_subnet.platform_private_c.cidr_block}"
}

output "bastion-public-subnet-a-cidr" {
  value = "${aws_subnet.bastion_a.cidr_block}"
}

output "bastion-public-subnet-b-cidr" {
  value = "${aws_subnet.bastion_b.cidr_block}"
}

output "bastion-public-subnet-c-cidr" {
  value = "${aws_subnet.bastion_c.cidr_block}"
}

output "openvpn-public-subnet-a-cidr" {
  value = "${aws_subnet.openvpn_a.cidr_block}"
}

output "openvpn-public-subnet-b-cidr" {
  value = "${aws_subnet.openvpn_b.cidr_block}"
}

output "openvpn-public-subnet-c-cidr" {
  value = "${aws_subnet.openvpn_c.cidr_block}"
}
