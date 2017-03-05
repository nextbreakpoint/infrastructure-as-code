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
# Elasticsearch configuration below
###################################################################

### MANDATORY ###
variable "elasticsearch_amis" {
}

variable "es_instance_type" {
  description = "Elasticsearch instance type."
  default = "t2.medium"
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

# number of nodes in zone a
variable "es_num_nodes_a" {
  description = "Elastic nodes in a"
  default = "1"
}

# number of nodes in zone b
variable "es_num_nodes_b" {
  description = "Elastic nodes in b"
  default = "1"
}

# the ability to add additional existing security groups. In our case we have consul running as agents on the box
variable "es_additional_security_groups" {
  default = ""
}

variable "minimum_master_nodes" {
  default = "1"
}

variable "availability_zones" {
  default = "eu-west-1a,eu-west-1b"
}

variable "elasticsearch_profile" {
  default = "elasticSearchNode"
}

variable "elastic_profile" {
  default = "elasticSearchNode"
}

###################################################################
# Consul configuration below
###################################################################

variable "consul_log_file" {
  default = "/var/log/consul.log"
}
