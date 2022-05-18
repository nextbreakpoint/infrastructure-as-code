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

variable "volume_type" {
  default = "standard"
}

variable "volume_size" {
  default = "8"
}

### MANDATORY ###
variable "hosted_zone_id" {}

### MANDATORY ###
variable "hosted_zone_name" {}

### MANDATORY ###
variable "key_name" {
  description = "Name of the SSH keypair to use in AWS."
  default     = "bastion"
}

variable "amazon_nat_ami" {
  default = {
    eu-west-1 = "ami-47ecb121"
  }
}

variable "instance_type" {
  default     = "t2.micro"
}

variable "bastion" {
  default     = false
}
