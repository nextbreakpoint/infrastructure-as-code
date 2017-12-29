##############################################################################
# Remote state
##############################################################################

terraform {
  backend "s3" {
    bucket = "nextbreakpoint-terraform"
    region = "eu-west-1"
    key = "elb.tfstate"
  }
}

data "terraform_remote_state" "vpc" {
    backend = "s3"
    config {
        bucket = "nextbreakpoint-terraform"
        region = "eu-west-1"
        key = "vpc.tfstate"
    }
}

data "terraform_remote_state" "network" {
    backend = "s3"
    config {
        bucket = "nextbreakpoint-terraform"
        region = "eu-west-1"
        key = "network.tfstate"
    }
}

data "terraform_remote_state" "webserver" {
    backend = "s3"
    config {
        bucket = "nextbreakpoint-terraform"
        region = "eu-west-1"
        key = "webserver.tfstate"
    }
}
