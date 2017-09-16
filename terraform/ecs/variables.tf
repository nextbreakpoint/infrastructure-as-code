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

### MANDATORY ###
variable "hosted_zone_name" {
}

### MANDATORY ###
variable "public_hosted_zone_id" {
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
# Cluster configuration below
###################################################################

variable "cluster_instance_type" {
  description = "cluster instance type."
  default  = "t2.medium"
}

### MANDATORY ###
variable "services_bucket_name" {
}

### MANDATORY ###
variable "ecs_cluster_elb_certificate_path" {
}

### MANDATORY ###
variable "ecs_cluster_elb_private_key_path" {
}
