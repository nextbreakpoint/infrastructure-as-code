##############################################################################
# Provider
##############################################################################

provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
  version = "~> 0.1"
}

provider "terraform" {
  version = "~> 0.1"
}

##############################################################################
# Remote state
##############################################################################

terraform {
  backend "s3" {
    bucket = "nextbreakpoint-terraform-state"
    region = "eu-west-1"
    key = "keys.tfstate"
  }
}

##############################################################################
# Keys
##############################################################################

resource "aws_key_pair" "terraform" {
  key_name   = "terraform"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDR+pPsmd6Nxb0ToxkbH2kT3K+uQaRdMCbUSqAnbmloI/p41/qvqay6ZB1QuoLQkir7D4VDn99W7WJTMeUcLfpPA9M0o4I4XTpSH/nyvlZQVaZziTRievPNQeQD7DSuHiYNWQh6OxAtxm2885mEQ327FPmDC0UnSY1hlHqStEzfbQ== andrea@MacBook-di-Andrea.local"
}
