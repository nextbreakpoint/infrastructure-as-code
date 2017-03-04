output "private-dns" {
  value = "${join(",", aws_instance.consul.*.private_dns)}"
}

output "private-ips" {
  value = "${join(",", aws_instance.consul.*.private_ip)}"
}

output "ids" {
  value = "${join(",", aws_instance.consul.*.id)}"
}
