###################################################################
# AWS configuration below
###################################################################

variable "aws_region" {
  default = "eu-west-1"
}

variable "aws_profile" {
  default = "default"
}

### MANDATORY ###
variable "key_name" {
  description = "Name of the SSH keypair to use in AWS."
}

### MANDATORY ###
variable "key_path" {
  description = "Path to the private portion of the SSH key specified."
}

variable "stream_tag" {
  default = "terraform"
}

###################################################################
# Route53 configuration below
###################################################################

### MANDATORY ###
variable "network_hosted_zone_name" {
}

### MANDATORY ###
variable "bastion_hosted_zone_name" {
}

### MANDATORY ###
variable "openvpn_hosted_zone_name" {
}

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
variable "aws_openvpn_vpc_cidr" {
  description = "OpenVPN cidr block"
}
