##############################################################################
# Remote state
##############################################################################

terraform {
  backend "s3" {
    bucket = "nextbreakpoint-terraform-wip"
    region = "eu-west-2"
    key    = "lbs.tfstate"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  workspace = var.workspace
  config = {
    bucket = "nextbreakpoint-terraform-wip"
    region = "eu-west-2"
    key    = "vpcs.tfstate"
  }
}

data "terraform_remote_state" "subnets" {
  backend = "s3"
  workspace = var.workspace
  config = {
    bucket = "nextbreakpoint-terraform-wip"
    region = "eu-west-2"
    key    = "subnets.tfstate"
  }
}
