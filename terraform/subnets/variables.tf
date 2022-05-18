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

/*
### MANDATORY ###
variable "key_name" {
  description = "Name of the SSH keypair to use in AWS."
}
*/

variable "enable_nat_gateways" {
  default = true
}

### MANDATORY ###
variable "aws_platform_private_subnet_cidr_a" {
  description = "Private subnet A cidr block"
}

### MANDATORY ###
variable "aws_platform_public_subnet_cidr_a" {
  description = "Public subnet A cidr block"
}

### MANDATORY ###
variable "aws_platform_private_subnet_cidr_b" {
  description = "Private subnet B cidr block"
}

### MANDATORY ###
variable "aws_platform_public_subnet_cidr_b" {
  description = "Public subnet B cidr block"
}

### MANDATORY ###
variable "aws_platform_private_subnet_cidr_c" {
  description = "Private subnet C cidr block"
}

### MANDATORY ###
variable "aws_platform_public_subnet_cidr_c" {
  description = "Public subnet C cidr block"
}

### MANDATORY ###
variable "aws_bastion_subnet_cidr_a" {
  description = "Bastion subnet A cidr block"
}

### MANDATORY ###
variable "aws_bastion_subnet_cidr_b" {
  description = "Bastion subnet B cidr block"
}

### MANDATORY ###
variable "aws_bastion_subnet_cidr_c" {
  description = "Bastion subnet C cidr block"
}

### MANDATORY ###
variable "aws_openvpn_subnet_cidr_a" {
  description = "OpenVPN subnet A cidr block"
}

### MANDATORY ###
variable "aws_openvpn_subnet_cidr_b" {
  description = "OpenVPN subnet B cidr block"
}

### MANDATORY ###
variable "aws_openvpn_subnet_cidr_c" {
  description = "OpenVPN subnet C cidr block"
}

/*
variable "amazon_nat_ami" {
  default = {
    eu-west-1 = "ami-47ecb121"
  }
}

variable "nat_instance_type" {
  default = "t2.micro"
}
*/
