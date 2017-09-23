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
# Secrets configuration below
###################################################################

### MANDATORY ###
variable "secrets_bucket_name" {
}
