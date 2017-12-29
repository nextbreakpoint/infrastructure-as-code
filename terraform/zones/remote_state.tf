##############################################################################
# Remote state
##############################################################################

terraform {
  backend "s3" {
    bucket = "terraform"
    region = "eu-west-1"
    key = "zones.tfstate"
  }
}

data "terraform_remote_state" "vpc" {
    backend = "s3"
    config {
        bucket = "terraform"
        region = "eu-west-1"
        key = "vpc.tfstate"
    }
}
