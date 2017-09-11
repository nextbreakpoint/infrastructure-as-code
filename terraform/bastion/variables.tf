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

variable "amazon_nat_amis" {
  default = {
    eu-west-1 = "ami-47ecb121"
  }
}

### MANDATORY ###
variable "public_hosted_zone_id" {
}

### MANDATORY ###
variable "public_hosted_zone_name" {
}

###################################################################
# Subnets configuration below
###################################################################

### MANDATORY ###
variable "aws_bastion_subnet_cidr_a" {
  description = "Bastion subnet A cidr block"
}

### MANDATORY ###
variable "aws_bastion_subnet_cidr_b" {
  description = "Bastion subnet B cidr block"
}
