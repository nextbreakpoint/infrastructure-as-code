output "kibana-server-a-private-ip" {
  value = "${aws_instance.kibana_server_a.private_ip}"
}

# output "kibana-server-b-private-ip" {
#   value = "${aws_instance.kibana_server_b.private_ip}"
# }
