output "pipeline-server-private-ip" {
  value = "${aws_instance.pipeline_server.private_ip}"
}
