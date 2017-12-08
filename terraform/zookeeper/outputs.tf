output "zookeeper-server-a-private-ip" {
  value = "${aws_instance.zookeeper_server_a.private_ip}"
}

output "zookeeper-server-b-private-ip" {
  value = "${aws_instance.zookeeper_server_b.private_ip}"
}

output "zookeeper-server-c-private-ip" {
  value = "${aws_instance.zookeeper_server_c.private_ip}"
}
