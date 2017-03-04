output "web-server-a-private-ip" {
  value = "${aws_instance.web_server_a.private_ip}"
}

output "web-server-b-private-ip" {
  value = "${aws_instance.web_server_b.private_ip}"
}

output "web-server-a-public-ip" {
  value = "${aws_instance.web_server_a.public_ip}"
}

output "web-server-b-public-ip" {
  value = "${aws_instance.web_server_b.public_ip}"
}

output "web-elb" {
  value = "${aws_elb.web.dns_name}"
}
