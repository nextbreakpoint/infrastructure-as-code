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

output "consul-datacenter" {
  value = "${var.consul_datacenter}"
}

output "consul-secret" {
  value = "${var.consul_secret}"
  sensitive = true
}

output "consul-master-token" {
  value = "${var.consul_master_token}"
  sensitive = true
}

output "aws-account-id" {
  value = "${var.account_id}"
}

output "hosted-zone-name" {
  value = "${var.hosted_zone_name}"
}

output "hosted-zone-id" {
  value = "${var.hosted_zone_id}"
}

output "bastion-hostname" {
  value = "${var.bastion_host}"
}

output "secrets-bucket-name" {
  value = "${var.secrets_bucket_name}"
}
