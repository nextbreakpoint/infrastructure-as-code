output "bastion-server-a-public-ip" {
  value = "${module.bastion_servers_a.public-ips}"
}
