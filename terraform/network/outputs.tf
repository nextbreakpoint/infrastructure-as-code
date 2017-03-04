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

/*
output "network-nat-a-public-ip" {
  value = "${aws_instance.network_nat_a.public_ip}"
}

output "network-nat-b-public-ip" {
  value = "${aws_instance.network_nat_b.public_ip}"
}

output "network-nat-c-public-ip" {
  value = "${aws_instance.network_nat_c.public_ip}"
}

output "network-nat-a-private-ip" {
  value = "${aws_instance.network_nat_a.private_ip}"
}

output "network-nat-b-private-ip" {
  value = "${aws_instance.network_nat_b.private_ip}"
}

output "network-nat-c-private-ip" {
  value = "${aws_instance.network_nat_c.private_ip}"
}
*/