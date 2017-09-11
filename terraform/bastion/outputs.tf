output "bastion-server-a-public-ip" {
  value = "${module.bastion_servers_a.public-ips}"
}

/*
output "bastion-server-b-public-ip" {
  value = "${module.bastion_servers_b.public-ips}"
}
*/
