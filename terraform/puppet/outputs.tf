output "puppet-server-private-ip" {
  value = "${aws_instance.puppet_server.private_ip}"
}

output "puppet-server-public-ip" {
  value = "${aws_instance.puppet_server.public_ip}"
}
