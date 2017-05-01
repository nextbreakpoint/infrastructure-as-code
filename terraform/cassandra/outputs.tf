output "cassandra-server-a1-private-ip" {
  value = "${aws_instance.cassandra_server_a1.private_ip}"
}

output "cassandra-server-b1-private-ip" {
  value = "${aws_instance.cassandra_server_b1.private_ip}"
}

output "cassandra-server-c1-private-ip" {
  value = "${aws_instance.cassandra_server_c1.private_ip}"
}

output "cassandra-server-a2-private-ip" {
  value = "${aws_instance.cassandra_server_a2.private_ip}"
}

output "cassandra-server-b2-private-ip" {
  value = "${aws_instance.cassandra_server_b2.private_ip}"
}

output "cassandra-server-c2-private-ip" {
  value = "${aws_instance.cassandra_server_c2.private_ip}"
}
