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
# ZooKeeper configuration below
###################################################################

### MANDATORY ###
variable "zookeeper_amis" {
  type = "map"
}

variable "aws_zookeeper_instance_type" {
  description = "zookeeper instance type."
  default  = "t2.small"
}

variable "zookeeper_log_file" {
  default = "/var/log/zookeeper/zookeeper.log"
}

variable "zookeeper_profile" {
  default = "zookeeperNode"
}

###################################################################
# Consul configuration below
###################################################################

variable "consul_log_file" {
  default = "/var/log/consul.log"
}
