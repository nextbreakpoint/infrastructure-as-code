output "developer-machine-private-ip" {
  value = "${aws_instance.developer_machine.private_ip}"
}

output "developer-machine-public-ip" {
  value = "${aws_instance.developer_machine.public_ip}"
}
