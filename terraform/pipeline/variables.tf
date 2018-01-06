###################################################################
# AWS configuration below
###################################################################

variable "aws_region" {
  default = "eu-west-1"
}

variable "aws_profile" {
  default = "default"
}

###################################################################
# Resources configuration below
###################################################################

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

variable "volume_name" {
  default = "/dev/xvdh"
}

variable "volume_size" {
  default = "8"
}

variable "volume_encrypted" {
  default = "false"
}

### MANDATORY ###
variable "aws_bastion_vpc_cidr" {}

### MANDATORY ###
variable "aws_network_vpc_cidr" {}

### MANDATORY ###
variable "aws_openvpn_vpc_cidr" {}

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
variable "account_id" {}

### MANDATORY ###
variable "environment" {
  default = "production"
}

### MANDATORY ###
variable "secrets_bucket_name" {}

variable "pipeline_instance_type" {
  default = "t2.medium"
}

### MANDATORY ###
variable "base_version" {}

### MANDATORY ###
variable "filebeat_version" {}

### MANDATORY ###
variable "jenkins_version" {}

### MANDATORY ###
variable "sonarqube_version" {}

### MANDATORY ###
variable "artifactory_version" {}

### MANDATORY ###
variable "mysqlconnector_version" {}

### MANDATORY ###
variable "mysql_root_password" {}

### MANDATORY ###
variable "mysql_sonarqube_password" {}

### MANDATORY ###
variable "mysql_artifactory_password" {}

### MANDATORY ###
variable "consul_secret" {}

variable "consul_datacenter" {
  default = "terraform"
}
