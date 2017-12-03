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

### MANDATORY ###
variable "base_version" {
}

### MANDATORY ###
variable "account_id" {
}

variable "environment" {
  default = "production"
}

### MANDATORY ###
variable "secrets_bucket_name" {
}

###################################################################
# Consul configuration below
###################################################################

### MANDATORY ###
variable "filebeat_version" {
}

### MANDATORY ###
variable "consul_secret" {
}

### MANDATORY ###
variable "consul_master_token" {
}

variable "consul_instance_type" {
  default = "t2.micro"
}

variable "consul_record" {
  default = "consul"
}

variable "consul_datacenter" {
  default = "terraform"
}

variable "consul_log_file" {
  default = "/var/log/consul.log"
}
