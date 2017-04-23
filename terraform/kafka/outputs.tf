output "kafka-server-a-private-ip" {
  value = "${aws_instance.kafka_server_a.private_ip}"
}

output "kafka-server-b-private-ip" {
  value = "${aws_instance.kafka_server_b.private_ip}"
}

output "kafka-server-c-private-ip" {
  value = "${aws_instance.kafka_server_c.private_ip}"
}
