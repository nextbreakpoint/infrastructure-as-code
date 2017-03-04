###################################################################
# AWS configuration below
###################################################################

### MANDATORY ###
variable "aws_access_key" {}

### MANDATORY ###
variable "aws_secret_key" {}

variable "stream_tag" {
  default = "terraform"
}

### MANDATORY ###
variable "key_name" {
  description = "Name of the SSH keypair to use in AWS."
}

### MANDATORY ###
variable "key_path" {
  description = "Path to the private portion of the SSH key specified."
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default = "eu-west-1"
}

###################################################################
# Route53 configuration below
###################################################################

### MANDATORY ###
variable "hosted_zone_name" {}

variable "public_hosted_zone_id" {}

variable "public_hosted_zone_name" {}

###################################################################
# VPC configuration below
###################################################################

### MANDATORY ###
variable "aws_network_vpc_cidr" {
  description = "Network VPC cidr block"
}

### MANDATORY ###
variable "aws_bastion_vpc_cidr" {
  description = "Bastion VPC cidr block"
}

### MANDATORY ###
variable "aws_peer_owner_id" {
  description = "VPC peering owner id"
}
