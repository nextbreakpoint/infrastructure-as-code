output "backend-server-a-private-ip" {
  value = "${aws_instance.backend_service_a.private_ip}"
}

output "backend-server-b-private-ip" {
  value = "${aws_instance.backend_service_b.private_ip}"
}
