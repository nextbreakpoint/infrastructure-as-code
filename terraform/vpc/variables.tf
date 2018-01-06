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

variable "stream_tag" {
  default = "terraform"
}

### MANDATORY ###
variable "aws_network_vpc_cidr" {
  description = "Network VPC cidr block"
}

### MANDATORY ###
variable "aws_bastion_vpc_cidr" {
  description = "Bastion VPC cidr block"
}

### MANDATORY ###
variable "aws_openvpn_vpc_cidr" {
  description = "OpenVPN VPC cidr block"
}
