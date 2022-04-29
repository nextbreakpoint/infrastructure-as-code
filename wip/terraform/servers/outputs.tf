##############################################################################
# Outputs
##############################################################################

output "server-a-id" {
  value = "${aws_instance.server_a.id}"
}

output "server-b-id" {
  value = "${aws_instance.server_b.id}"
}

output "server-c-id" {
  value = "${aws_instance.server_c.id}"
}

output "server-a-private-ip" {
  value = "${aws_instance.server_a.private_ip}"
}

output "server-b-private-ip" {
  value = "${aws_instance.server_b.private_ip}"
}

output "server-c-private-ip" {
  value = "${aws_instance.server_c.private_ip}"
}
