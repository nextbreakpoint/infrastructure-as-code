### MANDATORY ###
variable "hosted_zone_name" {}

### MANDATORY ###
variable "hosted_zone_id" {}

variable "key_name" {
  default = "server"
}

variable "cluster_name" {
  default = "k8s"
}

variable "cluster_version" {
  default = "1.22"
}

variable "cluster_ip_family" {
  default = "ipv4"
}

variable "cluster_service_ipv4_cidr" {
  default = "172.20.0.0/16"
}
