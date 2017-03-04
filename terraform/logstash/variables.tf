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

variable "amazon_ubuntu_ami" {
  default = {
    eu-west-1 = "ami-98ecb7fe"
  }
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

variable "volume_size" {
  default = "8"
}

variable "volume_encryption" {
  default = "false"
}

###################################################################
# Logstash configuration below
###################################################################

variable "aws_logstash_amis" {
  default = {
    eu-west-1 = "ami-d42506b2"
  }
}

variable "aws_logstash_instance_type" {
  description = "Logstash instance type."
  default = "t2.small"
}

### MANDATORY ###
# if you have multiple clusters sharing the same es_environment?
variable "es_cluster" {
  description = "Elastic cluster name"
}

### MANDATORY ###
variable "es_environment" {
  description = "Elastic environment tag for auto discovery"
  default = "terraform"
}

variable "logstash_log_file" {
  default = "/var/log/logstash.log"
}

variable "logstash_profile" {
  default = "logstashNode"
}

###################################################################
# Consul configuration below
###################################################################

variable "consul_log_file" {
  default = "/var/log/consul.log"
}
