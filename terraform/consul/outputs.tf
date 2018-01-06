##############################################################################
# Outputs
##############################################################################

output "consul-server-a-private-ip" {
  value = "${module.consul_a.private-ips}"
}

output "consul-server-b-private-ip" {
  value = "${module.consul_b.private-ips}"
}

output "consul-server-c-private-ip" {
  value = "${module.consul_c.private-ips}"
}
