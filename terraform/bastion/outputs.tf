output "bastion-server-a-public-ip" {
  value = "${module.bastion_servers_a.public-ips}"
}

output "bastion-server-b-public-ip" {
  value = "${module.bastion_servers_b.public-ips}"
}

output "bastion-server-a-private-ip" {
  value = "${module.bastion_servers_a.private-ips}"
}

output "bastion-server-b-private-ip" {
  value = "${module.bastion_servers_b.private-ips}"
}
