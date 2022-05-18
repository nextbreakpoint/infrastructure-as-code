##############################################################################
# Remote state
##############################################################################

terraform {
  backend "s3" {
    bucket = "nextbreakpoint-terraform-wip"
    region = "eu-west-2"
    key    = "keys.tfstate"
  }
}
