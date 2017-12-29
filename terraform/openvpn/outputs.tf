output "openvpn-server-a-public-ip" {
  value = "${aws_instance.openvpn_server_a.public_ip}"
}
