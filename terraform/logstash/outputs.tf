# output "logstash-server-a-private-ip" {
#   value = "${aws_instance.logstash_server_a.private_ip}"
# }
#
# output "logstash-server-b-private-ip" {
#   value = "${aws_instance.logstash_server_b.private_ip}"
# }

output "logstash-asg-id" {
  value = "${aws_autoscaling_group.logstash_asg.id}"
}
