##############################################################################
# Outputs
##############################################################################

output "openvpn-a-id" {
  value = "${aws_instance.openvpn_a.id}"
}

output "openvpn-a-private-ip" {
  value = "${aws_instance.openvpn_a.private_ip}"
}
