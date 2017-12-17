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
# Subnets configuration below
###################################################################

### MANDATORY ###
variable "aws_network_private_subnet_cidr_a" {
  description = "Private subnet A cidr block"
}

### MANDATORY ###
variable "aws_network_public_subnet_cidr_a" {
  description = "Public subnet A cidr block"
}

### MANDATORY ###
variable "aws_network_private_subnet_cidr_b" {
  description = "Private subnet B cidr block"
}

### MANDATORY ###
variable "aws_network_public_subnet_cidr_b" {
  description = "Public subnet B cidr block"
}

### MANDATORY ###
variable "aws_network_private_subnet_cidr_c" {
  description = "Private subnet C cidr block"
}

### MANDATORY ###
variable "aws_network_public_subnet_cidr_c" {
  description = "Public subnet C cidr block"
}

###################################################################
# NAT configuration
###################################################################

variable "amazon_nat_ami" {
  default = {
    eu-west-1 = "ami-47ecb121"
  }
}

variable "nat_instance_type" {
  default = "t2.micro"
}
