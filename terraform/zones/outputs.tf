output "bastion-hosted-zone-name" {
  value = "${aws_route53_zone.bastion.name}"
}

output "network-hosted-zone-name" {
  value = "${aws_route53_zone.network.name}"
}

output "bastion-hosted-zone-id" {
  value = "${aws_route53_zone.bastion.id}"
}

output "network-hosted-zone-id" {
  value = "${aws_route53_zone.network.id}"
}
