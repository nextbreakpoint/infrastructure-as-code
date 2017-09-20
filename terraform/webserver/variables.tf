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
variable "public_hosted_zone_id" {
}

### MANDATORY ###
variable "public_hosted_zone_name" {
}

### MANDATORY ###
variable "hosted_zone_name" {
}

### MANDATORY ###
variable "aws_bastion_vpc_cidr" {
}

### MANDATORY ###
variable "aws_network_vpc_cidr" {
}

###################################################################
# Server configuration below
###################################################################

### MANDATORY ###
variable "base_version" {
}

### MANDATORY ###
variable "account_id" {
}

variable "web_instance_type" {
  description = "NGINX instance type."
  default = "t2.small"
}

variable "environment" {
  default = "production"
}

### MANDATORY ###
variable "webserver_bucker_name" {
}

### MANDATORY ###
variable "web_server_elb_certificate_path" {
}

### MANDATORY ###
variable "web_server_elb_private_key_path" {
}

###################################################################
# Consul configuration below
###################################################################

variable "consul_log_file" {
  default = "/var/log/consul.log"
}
