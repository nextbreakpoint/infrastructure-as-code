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
variable "environment" {}

### MANDATORY ###
variable "colour" {}

### MANDATORY ###
variable "secrets_bucket_name" {}

### MANDATORY ###
variable "keystore_password" {}

### MANDATORY ###
variable "truststore_password" {}

### MANDATORY ###
variable "consul_secret" {}

### MANDATORY ###
variable "consul_master_token" {}
