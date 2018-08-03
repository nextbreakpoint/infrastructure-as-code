##############################################################################
# Remote state
##############################################################################

terraform {
  backend "s3" {
    bucket = "terraform"
    region = "eu-west-1"
    key    = "bastion.tfstate"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket = "terraform"
    region = "eu-west-1"
    key    = "env:/${terraform.workspace}/vpc.tfstate"
  }
}
