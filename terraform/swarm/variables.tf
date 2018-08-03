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

variable "volume_name" {
  default = "/dev/xvdh"
}

variable "volume_size" {
  default = "4"
}

variable "volume_encrypted" {
  default = "false"
}

### MANDATORY ###
variable "account_id" {}

### MANDATORY ###
variable "base_version" {}

### MANDATORY ###
variable "hosted_zone_name" {}

### MANDATORY ###
variable "hosted_zone_id" {}

### MANDATORY ###
variable "secrets_bucket_name" {}

### MANDATORY ###
variable "aws_bastion_vpc_cidr" {}

### MANDATORY ###
variable "aws_network_vpc_cidr" {}

### MANDATORY ###
variable "aws_openvpn_vpc_cidr" {}

### MANDATORY ###
variable "aws_network_private_subnet_cidr_a" {
  description = "Private subnet A cidr block"
}

### MANDATORY ###
variable "aws_network_private_subnet_cidr_b" {
  description = "Private subnet B cidr block"
}

### MANDATORY ###
variable "aws_network_private_subnet_cidr_c" {
  description = "Private subnet C cidr block"
}

variable "swarm_manager_instance_type" {
  default = "t2.xlarge"
}

variable "swarm_worker_instance_type" {
  default = "t2.2xlarge"
}
