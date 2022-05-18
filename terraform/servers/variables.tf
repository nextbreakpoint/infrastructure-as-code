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
variable "key_name" {
  description = "Name of the SSH keypair to use in AWS."
  default     = "server"
}

variable "instance_type" {
  default = "t2.small"
}

variable "volume_type" {
  default = "standard"
}

variable "volume_size" {
  default = "10"
}

### MANDATORY ###
variable "account_id" {}

### MANDATORY ###
variable "base_version" {}

### MANDATORY ###
variable "hosted_zone_name" {}

### MANDATORY ###
variable "hosted_zone_id" {}

### MANDATORY ###
variable "secrets_bucket_name" {}
