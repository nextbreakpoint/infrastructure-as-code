###################################################################
# AWS configuration below
###################################################################

variable "aws_region" {
  default = "eu-west-1"
}

variable "aws_profile" {
  default = "default"
}

variable "stream_tag" {
  default = "terraform"
}

###################################################################
# Route53 configuration below
###################################################################

### MANDATORY ###
variable "hosted_zone_name" {
}
