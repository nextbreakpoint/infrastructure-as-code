###################################################################
# AWS configuration below
###################################################################

variable "aws_region" {
  default = "eu-west-2"
}

###################################################################
# Resources configuration below
###################################################################

### MANDATORY ###
variable "environment" {}

### MANDATORY ###
variable "colour" {}

### MANDATORY ###
variable "workspace" {}

### MANDATORY ###
variable "hosted_zone_name" {}

### MANDATORY ###
variable "hosted_zone_id" {}

### MANDATORY ###
variable "cluster_name" {
  default = "k8s"
}

variable "cluster_version" {
  default = "1.22"
}

variable "cluster_ip_family" {
  default = "ipv4"
}

variable "cluster_service_ipv4_cidr" {
  default = "172.20.0.0/16"
}

### MANDATORY ###
variable "key_name" {
  description = "Name of the SSH keypair to use in AWS."
  default     = "server"
}
