##############################################################################
# Outputs
##############################################################################

output "secrets-created" {
  value = "true"
}

output "kafka-keystore-password" {
  value = "${var.keystore_password}"
  sensitive = true
}

output "kafka-truststore-password" {
  value = "${var.truststore_password}"
  sensitive = true
}

output "consul-secret" {
  value = "${var.consul_secret}"
  sensitive = true
}

output "consul-master-token" {
  value = "${var.consul_master_token}"
  sensitive = true
}
