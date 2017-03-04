output "elasticsearch-server-a-private-ip" {
  value = "${aws_instance.elasticsearch_server_a.private_ip}"
}

output "elasticsearch-server-b-private-ip" {
  value = "${aws_instance.elasticsearch_server_b.private_ip}"
}
