### MANDATORY ###
variable "aws_platform_vpc_cidr" {
  description = "Platform VPC cidr block"
}

### MANDATORY ###
variable "aws_bastion_vpc_cidr" {
  description = "Bastion VPC cidr block"
}

### MANDATORY ###
variable "aws_openvpn_vpc_cidr" {
  description = "OpenVPN VPC cidr block"
}
