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
variable "secrets_bucket_name" {}
