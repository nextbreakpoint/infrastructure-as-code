output "pipeline-server-private-ip" {
  value = "${aws_instance.pipeline_server.private_ip}"
}

output "pipeline-server-public-ip" {
  value = "${aws_instance.pipeline_server.public_ip}"
}
