output "openvpn-server-a-private-ip" {
  value = "${aws_instance.openvpn_server_a.private_ip}"
}
