##############################################################################
# Outputs
##############################################################################

# output "bastion-server-a-public-ip" {
#   value = "${module.bastion_a.public-ips}"
# }

# output "bastion-server-b-public-ip" {
#   value = "${module.bastion_b.public-ips}"
# }

# output "bastion-server-c-public-ip" {
#   value = "${module.bastion_c.public-ips}"
# }

output "bastion-public-subnet-a-id" {
  value = "${aws_subnet.bastion_a.id}"
}

output "bastion-public-subnet-b-id" {
  value = "${aws_subnet.bastion_b.id}"
}

output "bastion-public-subnet-c-id" {
  value = "${aws_subnet.bastion_c.id}"
}
