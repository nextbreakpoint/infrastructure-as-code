output "webserver-elb-dns-name" {
  value = "${aws_elb.webserver_elb.dns_name}"
}
