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

variable "amazon_nat_amis" {
  default = {
    eu-west-1 = "ami-47ecb121"
  }
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
