### MANDATORY ###
variable "hosted_zone_id" {}

### MANDATORY ###
variable "hosted_zone_name" {}

variable "key_name" {
  default = "bastion"
}

variable "amazon_nat_ami" {
  default = {
    eu-west-1 = "ami-47ecb121"
  }
}

variable "instance_type" {
  default = "t2.micro"
}

variable "volume_type" {
  default = "standard"
}

variable "volume_size" {
  default = "8"
}

variable "bastion" {
  default = false
}
