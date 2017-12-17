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

variable "log_group_name" {
  default = "terraform"
}

variable "log_stream_name" {
  default = "terraform"
}

### MANDATORY ###
variable "public_hosted_zone_name" {
}

### MANDATORY ###
variable "public_hosted_zone_id" {
}

###################################################################
# OpenVPN configuration below
###################################################################

### MANDATORY ###
variable "openvpn_ami" {
}

### MANDATORY ###
variable "openvpn_instance_type" {
  default = "t2.micro"
}

###################################################################
# Subnets configuration below
###################################################################

### MANDATORY ###
variable "aws_openvpn_subnet_cidr_a" {
  description = "OpenVPN subnet A cidr block"
}

### MANDATORY ###
variable "aws_openvpn_subnet_cidr_b" {
  description = "OpenVPN subnet B cidr block"
}
