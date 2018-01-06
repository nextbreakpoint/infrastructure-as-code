##############################################################################
# Outputs
##############################################################################

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
