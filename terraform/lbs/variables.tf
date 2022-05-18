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
