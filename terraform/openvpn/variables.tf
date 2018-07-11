###################################################################
# AWS configuration below
###################################################################

variable "aws_region" {
  default = "eu-west-1"
}

variable "aws_profile" {
  default = "default"
}

###################################################################
# Resources configuration below
###################################################################

### MANDATORY ###
variable "environment" {}

### MANDATORY ###
variable "colour" {}

### MANDATORY ###
variable "key_name" {
  description = "Name of the SSH keypair to use in AWS."
}

### MANDATORY ###
variable "base_version" {}

### MANDATORY ###
variable "account_id" {}

### MANDATORY ###
variable "hosted_zone_name" {}

### MANDATORY ###
variable "hosted_zone_id" {}

### MANDATORY ###
variable "aws_network_vpc_cidr" {}

### MANDATORY ###
variable "aws_openvpn_vpc_cidr" {}

### MANDATORY ###
variable "aws_bastion_vpc_cidr" {}

### MANDATORY ###
variable "secrets_bucket_name" {}

variable "openvpn_cidr" {
  default = "10.8.0.0/16"
}

### MANDATORY ###
variable "aws_openvpn_subnet_cidr_a" {}

### MANDATORY ###
variable "aws_openvpn_subnet_cidr_b" {}

### MANDATORY ###
variable "aws_openvpn_subnet_cidr_c" {}

variable "openvpn_instance_type" {
  default = "t2.small"
}
