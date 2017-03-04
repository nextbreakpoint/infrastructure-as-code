output "consul-server-a-private-ip" {
  value = "${module.consul_servers_a.private-ips}"
}

output "consul-server-b-private-ip" {
  value = "${module.consul_servers_b.private-ips}"
}

output "consul-server-c-private-ip" {
  value = "${module.consul_servers_c.private-ips}"
}
