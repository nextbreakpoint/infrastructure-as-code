##############################################################################
# Outputs
##############################################################################

output "bastion_key_name" {
  value = "${aws_key_pair.bastion.key_name}"
}

output "openvpn_key_name" {
  value = "${aws_key_pair.openvpn.key_name}"
}

output "server_key_name" {
  value = "${aws_key_pair.server.key_name}"
}

output "packer_key_name" {
  value = "${aws_key_pair.packer.key_name}"
}
