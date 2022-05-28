output "openvpn-a-private-ip" {
  value = "${aws_instance.openvpn_a[0].private_ip}"
}

# output "openvpn-b-private-ip" {
#   value = "${aws_instance.openvpn_b[0].private_ip}"
# }
