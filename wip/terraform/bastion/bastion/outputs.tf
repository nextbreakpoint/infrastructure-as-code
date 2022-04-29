output "private-ips" {
  value = "${join(",", aws_instance.bastion.*.private_ip)}"
}

output "public-ips" {
  value = "${join(",", aws_instance.bastion.*.public_ip)}"
}

output "ids" {
  value = "${join(",", aws_instance.bastion.*.id)}"
}
