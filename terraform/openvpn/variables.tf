### MANDATORY ###
variable "hosted_zone_name" {}

### MANDATORY ###
variable "hosted_zone_id" {}

variable "key_name" {
  default = "openvpn"
}

variable "instance_type" {
  default = "t2.small"
}

variable "volume_type" {
  default = "standard"
}

variable "volume_size" {
  default = "8"
}

variable "openvpn_cidr" {
  default = "10.8.0.0/16"
}

### MANDATORY ###
variable "openvpn_image_version" {}

### MANDATORY ###
variable "openvpn_bucket_name" {}

### MANDATORY ###
variable "openvpn_key_password" {}

### MANDATORY ###
variable "openvpn_keystore_password" {}

### MANDATORY ###
variable "openvpn_truststore_password" {}

variable "openvpn" {
  default = false
}
