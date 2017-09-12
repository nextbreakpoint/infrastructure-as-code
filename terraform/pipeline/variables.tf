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

variable "volume_name" {
  default = "/dev/xvdh"
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
# Pipeline configuration below
###################################################################

### MANDATORY ###
variable "jenkins_version" {
}

### MANDATORY ###
variable "sonarqube_version" {
}

### MANDATORY ###
variable "artifactory_version" {
}

### MANDATORY ###
variable "mysqlconnector_version" {
}

### MANDATORY ###
variable "base_version" {
}

### MANDATORY ###
variable "account_id" {
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
