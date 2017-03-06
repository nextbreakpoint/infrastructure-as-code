output "maintenance-server-a-private-ip" {
  value = "${aws_instance.maintenance_server_a.private_ip}"
}

output "maintenance-server-a-public-ip" {
  value = "${aws_instance.maintenance_server_a.public_ip}"
}

output "maintenance-server-b-private-ip" {
  value = "${aws_instance.maintenance_server_b.private_ip}"
}

output "maintenance-server-b-public-ip" {
  value = "${aws_instance.maintenance_server_b.public_ip}"
}
