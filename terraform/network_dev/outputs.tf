output "network-public-subnet-a-id" {
  value = "${aws_subnet.network_dev_public_a.id}"
}

output "network-private-subnet-a-id" {
  value = "${aws_subnet.network_dev_private_a.id}"
}
