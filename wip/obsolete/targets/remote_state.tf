##############################################################################
# Remote state
##############################################################################

terraform {
  backend "s3" {
    bucket = "terraform"
    region = "eu-west-1"
    key    = "targets.tfstate"
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

data "terraform_remote_state" "network" {
  backend = "s3"

  config {
    bucket = "terraform"
    region = "eu-west-1"
    key    = "env:/${terraform.workspace}/network.tfstate"
  }
}

data "terraform_remote_state" "swarm" {
  backend = "s3"

  config {
    bucket = "terraform"
    region = "eu-west-1"
    key    = "env:/${terraform.workspace}/swarm.tfstate"
  }
}

data "terraform_remote_state" "lb" {
  backend = "s3"

  config {
    bucket = "terraform"
    region = "eu-west-1"
    key    = "env:/${terraform.workspace}/lb.tfstate"
  }
}
