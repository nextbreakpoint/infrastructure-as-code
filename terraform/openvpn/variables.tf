###################################################################
# AWS configuration below
###################################################################

variable "aws_region" {
  default = "eu-west-2"
}

###################################################################
# Resources configuration below
###################################################################

### MANDATORY ###
variable "environment" {}

### MANDATORY ###
variable "colour" {}

### MANDATORY ###
variable "workspace" {}

### MANDATORY ###
variable "key_name" {
  description = "Name of the SSH keypair to use in AWS."
  default     = "openvpn"
}

variable "volume_type" {
  default = "standard"
}

variable "volume_size" {
  default = "8"
}

### MANDATORY ###
variable "hosted_zone_name" {}

### MANDATORY ###
variable "hosted_zone_id" {}

### MANDATORY ###
variable "account_id" {}

### MANDATORY ###
variable "base_version" {}

### MANDATORY ###
variable "secrets_bucket_name" {}

variable "openvpn_cidr" {
  default = "10.8.0.0/16"
}

variable "instance_type" {
  default = "t2.small"
}

### MANDATORY ###
variable "openvpn_key_password" {}

### MANDATORY ###
variable "openvpn_keystore_password" {}

### MANDATORY ###
variable "openvpn_truststore_password" {}
