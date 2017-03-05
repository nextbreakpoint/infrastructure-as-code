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

variable "log_group_name" {
  default = "terraform"
}

variable "log_stream_name" {
  default = "terraform"
}

###################################################################
# Consul configuration below
###################################################################

### MANDATORY ###
variable "consul_amis" {
}

variable "allowed_cidr_blocks" {
  default = "0.0.0.0/0"
}

variable "consul_log_file" {
  default = "/var/log/consul.log"
}

variable "consul_profile" {
  default = "consulNode"
}

### MANDATORY ###
variable "environment" {
  description = "Elastic environment tag for auto discovery"
  default = "terraform"
}
