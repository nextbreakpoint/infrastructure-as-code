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

variable "volume_size" {
  default = "4"
}

variable "volume_encrypted" {
  default = "false"
}

### MANDATORY ###
variable "aws_bastion_vpc_cidr" {
}

### MANDATORY ###
variable "aws_openvpn_vpc_cidr" {
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
variable "account_id" {
}

### MANDATORY ###
variable "environment" {
  default = "production"
}

### MANDATORY ###
variable "secrets_bucket_name" {
}

###################################################################
# Pipeline configuration below
###################################################################

### MANDATORY ###
variable "base_version" {
}

### MANDATORY ###
variable "filebeat_version" {
}

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
variable "mysql_root_password" {
}

### MANDATORY ###
variable "mysql_sonarqube_password" {
}

### MANDATORY ###
variable "mysql_artifactory_password" {
}

###################################################################
# Consul configuration below
###################################################################

### MANDATORY ###
variable "consul_secret" {
}

variable "consul_record" {
  default = "consul"
}

variable "consul_datacenter" {
  default = "terraform"
}

variable "consul_logfile" {
  default = "/var/log/consul.log"
}
