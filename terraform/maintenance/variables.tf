###################################################################
# AWS configuration below
###################################################################

### MANDATORY ###
variable "aws_shared_credentials_file" {
}

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

### MANDATORY ###
variable "hosted_zone_name" {
}

### MANDATORY ###
variable "public_hosted_zone_name" {
}

### MANDATORY ###
variable "aws_bastion_vpc_cidr" {
}

### MANDATORY ###
variable "aws_network_vpc_cidr" {
}

###################################################################
# Maintenance configuration below
###################################################################

### MANDATORY ###
variable "amazon_ubuntu_amis" {
  type = "map"
  default = {
    eu-west-1 = "ami-98ecb7fe"
  }
}

variable "elasticsearch_device_name" {
  default = "/dev/xvdh"
}

variable "pipeline_device_name" {
  default = "/dev/xvdi"
}
