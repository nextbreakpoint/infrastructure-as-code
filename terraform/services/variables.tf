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

variable "log_group_name" {
  default = "terraform"
}

variable "log_stream_name" {
  default = "terraform"
}

###################################################################
# Services configuration below
###################################################################

### MANDATORY ###
variable "base_amis" {
  type = "map"
}

variable "service_profile" {
  default = "service"
}

### MANDATORY ###
variable "environment" {
  default = "terraform"
}

###################################################################
# Consul configuration below
###################################################################

variable "consul_log_file" {
  default = "/var/log/consul.log"
}
