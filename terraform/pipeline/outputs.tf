output "pipeline-server-a-private-ip" {
  value = "${aws_instance.pipeline_server_a.private_ip}"
}
