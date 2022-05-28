### MANDATORY ###
variable "hosted_zone_name" {}

### MANDATORY ###
variable "hosted_zone_id" {}

variable "key_name" {
  default = "server"
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
variable "server_image_version" {}
